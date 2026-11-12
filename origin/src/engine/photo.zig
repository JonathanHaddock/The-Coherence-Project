//! Photograph mode (RULE CHOICES 12-14, November 12, 2026).
//!
//! Base engine: the 3D lattice (grid3) with one_cell display and sweep update.
//! 12: a flash realizes the pattern the pixel shows after flashing: the photograph.
//! 13: the flash emits a neutrino = unrealized possibility. Its makeup is, per
//!     position, the share of unrealized patterns with that position filled.
//!       all7: the 7 other patterns count equally   -> 3/7 or 4/7
//!       next: only the 3 one-flip patterns count     -> 2/3 or 1/3
//! 14: neutrinos travel as a 3-channel field, one hop per tick, wrapped,
//!     nothing lost, no effect on the pixels.

const std = @import("std");
const px = @import("pixel.zig");
const g3 = @import("grid3.zig");

pub const n = g3.n;
pub const Weight = enum { all7, next };
/// RULE CHOICE 15: neutrino delivery by information, not space.
pub const Deliver = enum { none, same, unreal };

/// Neutrino makeup for a realized pattern.
pub fn makeup(p: u3, w: Weight) [3]f64 {
    var m: [3]f64 = .{ 0, 0, 0 };
    var count: f64 = 0;
    for (0..8) |qi| {
        const q: u3 = @intCast(qi);
        if (q == p) continue;
        if (w == .next and @popCount(q ^ p) != 1) continue;
        count += 1;
        for (0..3) |k| {
            if ((q >> @intCast(k)) & 1 == 1) m[k] += 1;
        }
    }
    for (&m) |*v| v.* /= count;
    return m;
}

/// D: 0 = identity (equal shares), 1 = all in one position.
pub fn dOf(v: [3]f64) f64 {
    const s = v[0] + v[1] + v[2];
    if (s == 0) return 0;
    const q = (v[0] * v[0] + v[1] * v[1] + v[2] * v[2]) / (s * s);
    return 1.5 * (q - 1.0 / 3.0);
}

pub const Photo = struct {
    g: g3.Grid3,
    field: [n][3]f64,
    nxt: [n][3]f64,
    weight: Weight,
    realized: [8]u64,
    emitted_d_max: f64,
    emitted_d_sum: f64,
    emitted: u64,
    totals: [3]f64,
    before: [n]u3,
    /// quark flash: flips per position, [k][0] = empty->filled, [k][1] = filled->empty
    flips: [3][2]u64,
    no_flip: u64,
    /// charge change per event in thirds, by filled-count change -1, 0, +1
    charge_steps: [3]u64,
    /// electron flash: D of the displayed pattern vector (patterns 000 excluded, D undefined)
    elec_d_sum: f64,
    elec_n: u64,
    /// bookkeeping: events where display + 7 x all7-share != 4 in some position
    whole_fail: u64,
    deliver: Deliver,
    /// RULE CHOICE 16: fractional memory waiting to become whole units; and total received.
    acc: [n][3]f64,
    recv: [n][3]f64,

    pub fn init(p: *Photo, w: Weight, seed: u64) void {
        p.g.init(.{ .display = .one_cell, .update = .sweep, .start = .random, .seed = seed });
        p.g.gravity = false;
        p.field = @splat(.{ 0, 0, 0 });
        p.weight = w;
        p.realized = @splat(0);
        p.emitted_d_max = 0;
        p.emitted_d_sum = 0;
        p.emitted = 0;
        p.totals = .{ 0, 0, 0 };
        p.flips = .{ .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 } };
        p.no_flip = 0;
        p.charge_steps = .{ 0, 0, 0 };
        p.elec_d_sum = 0;
        p.elec_n = 0;
        p.whole_fail = 0;
        p.deliver = .none;
        p.acc = @splat(.{ 0, 0, 0 });
        p.recv = @splat(.{ 0, 0, 0 });
    }

    pub fn tick(p: *Photo, t: i64) u32 {
        for (0..n) |i| p.before[i] = p.g.px[i].pattern;
        const c = p.g.tick(t, if (t == 0) g3.index(g3.side / 2, g3.side / 2, g3.side / 2) else null);
        for (0..n) |i| {
            if (!p.g.fired[i]) continue;
            const pat = p.g.px[i].pattern;
            p.realized[pat] += 1;
            // quark flash
            const diff = pat ^ p.before[i];
            if (diff == 0) p.no_flip += 1;
            for (0..3) |k| {
                if ((diff >> @intCast(k)) & 1 == 1) {
                    const now_filled = (pat >> @intCast(k)) & 1 == 1;
                    p.flips[k][if (now_filled) 0 else 1] += 1;
                }
            }
            const dc: i32 = @as(i32, @popCount(pat)) - @as(i32, @popCount(p.before[i]));
            p.charge_steps[@intCast(@max(-1, @min(1, dc)) + 1)] += 1;
            // electron flash
            if (pat != 0) {
                var ev: [3]f64 = undefined;
                for (0..3) |k| ev[k] = @floatFromInt((pat >> @intCast(k)) & 1);
                p.elec_d_sum += dOf(ev);
                p.elec_n += 1;
            }
            // bookkeeping: display + unrealized = whole
            const a7 = makeup(pat, .all7);
            for (0..3) |k| {
                const tot = @as(f64, @floatFromInt((pat >> @intCast(k)) & 1)) + 7 * a7[k];
                if (@abs(tot - 4) > 1e-9) {
                    p.whole_fail += 1;
                    break;
                }
            }
            const m = makeup(pat, p.weight);
            const d = dOf(m);
            p.emitted_d_max = @max(p.emitted_d_max, d);
            p.emitted_d_sum += d;
            p.emitted += 1;
            for (0..3) |k| {
                p.field[i][k] += m[k];
                p.totals[k] += m[k];
            }
        }
        p.spread();
        if (p.deliver != .none) p.deliverNu();
        return c;
    }

    /// RULES 15-16: each photograph's neutrino goes, in the same tick, to pixels
    /// linked by pattern (same, or one of the 7 unrealized), split evenly, and
    /// arrives as memory: each whole unit per position becomes +1 conserved.
    fn deliverNu(p: *Photo) void {
        var emit: [8][3]f64 = @splat(.{ 0, 0, 0 });
        for (0..n) |i| {
            if (!p.g.fired[i]) continue;
            const pat = p.g.px[i].pattern;
            const m = makeup(pat, .all7);
            for (0..3) |k| emit[pat][k] += m[k];
        }
        var n_of: [8]f64 = @splat(0);
        for (0..n) |i| n_of[p.g.px[i].pattern] += 1;
        var to: [8][3]f64 = @splat(.{ 0, 0, 0 });
        for (0..8) |a| {
            if (emit[a][0] == 0 and emit[a][1] == 0 and emit[a][2] == 0) continue;
            if (p.deliver == .same) {
                for (0..3) |k| to[a][k] += emit[a][k];
            } else {
                var tot: f64 = 0;
                for (0..8) |b| {
                    if (b != a) tot += n_of[b];
                }
                if (tot == 0) continue;
                for (0..8) |b| {
                    if (b == a or n_of[b] == 0) continue;
                    for (0..3) |k| to[b][k] += emit[a][k] * n_of[b] / tot;
                }
            }
        }
        for (0..n) |i| {
            const q = p.g.px[i].pattern;
            const cnt = n_of[q];
            if (cnt == 0) continue;
            for (0..3) |k| {
                const v = to[q][k] / cnt;
                if (v == 0) continue;
                p.recv[i][k] += v;
                const a = p.acc[i][k] + v;
                const whole = @floor(a);
                p.acc[i][k] = a - whole;
                if (whole > 0) p.g.px[i].conserved[k] += @intFromFloat(whole);
            }
        }
    }

    fn spread(p: *Photo) void {
        p.nxt = @splat(.{ 0, 0, 0 });
        for (0..n) |i| {
            const v = p.field[i];
            if (v[0] == 0 and v[1] == 0 and v[2] == 0) continue;
            for (g3.neighbors(i)) |j| for (0..3) |k| {
                p.nxt[j][k] += v[k] / 6.0;
            };
        }
        p.field = p.nxt;
    }
};

test "makeup: all7 gives 3/7 and 4/7, next gives 2/3 and 1/3" {
    const a = makeup(0b001, .all7);
    try std.testing.expectApproxEqAbs(3.0 / 7.0, a[0], 1e-12);
    try std.testing.expectApproxEqAbs(4.0 / 7.0, a[1], 1e-12);
    const b = makeup(0b001, .next);
    try std.testing.expectApproxEqAbs(2.0 / 3.0, b[0], 1e-12);
    try std.testing.expectApproxEqAbs(1.0 / 3.0, b[1], 1e-12);
}

test "makeup is identity for 000 and 111" {
    for ([_]Weight{ .all7, .next }) |w| {
        try std.testing.expectApproxEqAbs(@as(f64, 0), dOf(makeup(0b000, w)), 1e-12);
        try std.testing.expectApproxEqAbs(@as(f64, 0), dOf(makeup(0b111, w)), 1e-12);
    }
}
