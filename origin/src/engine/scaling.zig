//! How does a region's flashing grow with its size?
//!
//! On the 3D lattice, take cubes of n pixels (side 1, 2, 4, 8, 16, 24). Count
//! the flashes in each cube over windows of W ticks, and see how much that
//! count wobbles from window to window. Fit  wobble ~ n^a :
//!   a = 1    members flash in step (their flashes pile up)
//!   a = 1/2  members keep their own timing (their flashes partly cancel)
//! a = 1/2 is the "halfway" falloff behind the zeta zeros: per member, the
//! strength goes as 1/sqrt(n).
//!
//! Two counts:
//!   pixels:     every flash counts
//!   identities: pixels flashing together that are adjacent and now show the
//!               same pattern count as ONE (one identity, one flash), the same
//!               rule the region clocks use
//!
//! Two controls, same lattice and rate, not part of the engine:
//!   independent: every pixel flashes with the engine's own average rate,
//!                each on its own (seeded, repeatable)
//!   in step:     all pixels flash on the same ticks, same average rate

const std = @import("std");
const px = @import("pixel.zig");
const g3 = @import("grid3.zig");

pub const sides = [_]usize{ 1, 2, 4, 8, 16, 24 };
const n = g3.n;
const S = sides.len;

pub const Fit = struct {
    wobble: [S]f64,
    mean: [S]f64,
    a: f64, // slope of log wobble against log n
};

const Acc = struct {
    cur: [S][]f64,
    sum: [S][]f64,
    sq: [S][]f64,
    windows: f64 = 0,

    fn init(gpa: std.mem.Allocator) !Acc {
        var a: Acc = .{ .cur = undefined, .sum = undefined, .sq = undefined };
        for (sides, 0..) |s, k| {
            const per = g3.side / s;
            const nb = per * per * per;
            a.cur[k] = try gpa.alloc(f64, nb);
            a.sum[k] = try gpa.alloc(f64, nb);
            a.sq[k] = try gpa.alloc(f64, nb);
            @memset(a.cur[k], 0);
            @memset(a.sum[k], 0);
            @memset(a.sq[k], 0);
        }
        return a;
    }
    fn deinit(a: *Acc, gpa: std.mem.Allocator) void {
        for (0..S) |k| {
            gpa.free(a.cur[k]);
            gpa.free(a.sum[k]);
            gpa.free(a.sq[k]);
        }
    }
    fn hit(a: *Acc, block_of: *const [S][]u32, i: usize, w: f64) void {
        for (0..S) |k| a.cur[k][block_of[k][i]] += w;
    }
    fn close(a: *Acc) void {
        for (0..S) |k| for (a.cur[k], a.sum[k], a.sq[k]) |*c, *s, *q| {
            s.* += c.*;
            q.* += c.* * c.*;
            c.* = 0;
        };
        a.windows += 1;
    }
    fn fit(a: *const Acc) Fit {
        var f: Fit = .{ .wobble = undefined, .mean = undefined, .a = 0 };
        for (0..S) |k| {
            var wob: f64 = 0;
            var mean: f64 = 0;
            for (a.sum[k], a.sq[k]) |s, q| {
                const m = s / a.windows;
                wob += @sqrt(@max(0, q / a.windows - m * m));
                mean += m;
            }
            const nb: f64 = @floatFromInt(a.sum[k].len);
            f.wobble[k] = wob / nb;
            f.mean[k] = mean / nb;
        }
        var sx: f64 = 0;
        var sy: f64 = 0;
        var sxx: f64 = 0;
        var sxy: f64 = 0;
        for (sides, 0..) |s, k| {
            const x = 3 * @log(@as(f64, @floatFromInt(s)));
            const y = @log(f.wobble[k]);
            sx += x;
            sy += y;
            sxx += x * x;
            sxy += x * y;
        }
        const m: f64 = @floatFromInt(S);
        f.a = (m * sxy - sx * sy) / (m * sxx - sx * sx);
        return f;
    }
};

pub const Result = struct {
    pixels: Fit,
    identities: Fit,
    independent: Fit,
    in_step: Fit,
    rate: f64, // flashes per pixel per tick
    mean_group: f64, // average pixels per identity group
};

fn find(parent: []u32, x: u32) u32 {
    var r = x;
    while (parent[r] != r) r = parent[r];
    var y = x;
    while (parent[y] != r) {
        const nx = parent[y];
        parent[y] = r;
        y = nx;
    }
    return r;
}

const Rng = struct {
    s: u64,
    fn next(r: *Rng) u64 {
        r.s ^= r.s << 13;
        r.s ^= r.s >> 7;
        r.s ^= r.s << 17;
        return r.s;
    }
    fn unit(r: *Rng) f64 {
        return (@as(f64, @floatFromInt(r.next() >> 11)) + 0.5) / 9007199254740992.0;
    }
};

pub fn measure(gpa: std.mem.Allocator, cfg: px.Config, ticks: i64, settle: i64, window: i64) !Result {
    const g = try gpa.create(g3.Grid3);
    defer gpa.destroy(g);
    g.init(cfg);

    var block_of: [S][]u32 = undefined;
    for (sides, 0..) |s, k| {
        block_of[k] = try gpa.alloc(u32, n);
        const per = g3.side / s;
        for (0..n) |i| {
            const c = g3.coords(i);
            block_of[k][i] = @intCast(((c[2] / s) * per + c[1] / s) * per + c[0] / s);
        }
    }
    defer for (0..S) |k| gpa.free(block_of[k]);

    var acc_px = try Acc.init(gpa);
    defer acc_px.deinit(gpa);
    var acc_id = try Acc.init(gpa);
    defer acc_id.deinit(gpa);
    var acc_ind = try Acc.init(gpa);
    defer acc_ind.deinit(gpa);
    var acc_step = try Acc.init(gpa);
    defer acc_step.deinit(gpa);

    const parent = try gpa.alloc(u32, n);
    defer gpa.free(parent);

    var flashes: f64 = 0;
    var groups: f64 = 0;
    var t: i64 = 0;
    var in_window: i64 = 0;
    const centre = g3.index(g3.side / 2, g3.side / 2, g3.side / 2);
    while (t < ticks) : (t += 1) {
        _ = g.tick(t, if (t == 0) centre else null);
        if (t < settle) continue;
        for (0..n) |i| parent[i] = @intCast(i);
        for (0..n) |i| {
            if (!g.fired[i]) continue;
            acc_px.hit(&block_of, i, 1);
            flashes += 1;
            const nb = g3.neighbors(i);
            for ([_]usize{ nb[0], nb[2], nb[4] }) |j| {
                if (!g.fired[j] or g.px[i].pattern != g.px[j].pattern) continue;
                const ra = find(parent, @intCast(i));
                const rb = find(parent, @intCast(j));
                if (ra != rb) parent[ra] = rb;
            }
        }
        for (0..n) |i| {
            if (g.fired[i] and find(parent, @intCast(i)) == i) {
                acc_id.hit(&block_of, i, 1);
                groups += 1;
            }
        }
        in_window += 1;
        if (in_window == window) {
            acc_px.close();
            acc_id.close();
            in_window = 0;
        }
    }
    const live: f64 = @floatFromInt(ticks - settle);
    const rate = flashes / (live * @as(f64, @floatFromInt(n)));

    // Controls at the same rate and length. Independent flashes are placed by
    // jumping ahead a seeded geometric gap, so each pixel-tick has chance `rate`.
    var rng: Rng = .{ .s = 20261125 };
    const lq = @log(1 - @min(rate, 0.999999));
    t = settle;
    in_window = 0;
    var pos: f64 = @floor(@log(rng.unit()) / lq);
    const total_cells: f64 = live * @as(f64, @floatFromInt(n));
    var cell: f64 = 0;
    while (t < ticks) : (t += 1) {
        const end = cell + @as(f64, @floatFromInt(n));
        while (pos < end and pos < total_cells) {
            acc_ind.hit(&block_of, @intFromFloat(pos - cell), 1);
            pos += 1 + @floor(@log(rng.unit()) / lq);
        }
        cell = end;
        if (rng.unit() < rate) {
            for (0..S) |k| for (acc_step.cur[k]) |*c| {
                c.* += @floatFromInt(sides[k] * sides[k] * sides[k]);
            };
        }
        in_window += 1;
        if (in_window == window) {
            acc_ind.close();
            acc_step.close();
            in_window = 0;
        }
    }

    return .{
        .pixels = acc_px.fit(),
        .identities = acc_id.fit(),
        .independent = acc_ind.fit(),
        .in_step = acc_step.fit(),
        .rate = rate,
        .mean_group = if (groups > 0) flashes / groups else 0,
    };
}

test "controls land where they should" {
    const r = try measure(std.testing.allocator, .{ .display = .one_cell }, 400, 100, 2);
    try std.testing.expect(r.rate > 0.01);
    try std.testing.expectApproxEqAbs(0.5, r.independent.a, 0.05);
    try std.testing.expectApproxEqAbs(1.0, r.in_step.a, 0.05);
}
