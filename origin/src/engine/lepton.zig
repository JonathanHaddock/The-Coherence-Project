//! Lepton mode (RULE CHOICES 7-9, November 10, 2026).
//! Cells are the three lepton generations: cell 0 = e, 1 = mu, 2 = tau.
//! The neutrino flash keeps its content: the conserved share on cell k goes
//! into carrier channel k. Channels spread one hop per tick on wrapped edges
//! (nothing lost). A whole unit in channel k at a site is absorbed and acts as
//! the section 5 flash rule with generation k shown filled: reinforce k if the
//! pixel has k filled, else add to its memory on k.

const std = @import("std");
const px = @import("pixel.zig");
const g3 = @import("grid3.zig");

pub const n = g3.n;

pub const Lepton = struct {
    px: [n]px.Pixel,
    fired: [n]bool,
    car: [n][3]f64,
    nxt: [n][3]f64,

    pub fn init(g: *Lepton, seed: u64, core: u32) void {
        g.fired = @splat(false);
        g.car = @splat(.{ 0, 0, 0 });
        var s = seed;
        for (&g.px) |*p| {
            s ^= s << 13;
            s ^= s >> 7;
            s ^= s << 17;
            p.* = .{ .pattern = @truncate(s) };
            for (0..px.cells) |k| p.conserved[k] = @intCast((s >> @intCast(8 + 2 * k)) % 2);
        }
        if (core > 0) for (&g.px, 0..) |*p, i| {
            if (g3.radius(i) <= @as(f64, @floatFromInt(core))) {
                p.pattern = 0b111;
                p.conserved = .{ 1, 1, 1 };
            }
        };
    }

    pub fn tick(g: *Lepton, t: i64, kick: ?usize) u32 {
        var count: u32 = 0;
        for (0..n) |i| g.fired[i] = g.px[i].ready() or kick == i;
        for (0..n) |i| if (g.fired[i]) {
            const p = &g.px[i];
            for (0..3) |k| g.car[i][k] += @floatFromInt(p.conserved[k]);
            _ = p.flashWith(t, .one_cell);
            count += 1;
        };
        for (0..n) |i| {
            if (!g.fired[i]) continue;
            for (g3.neighbors(i)) |j| g.px[j].receive(g.px[i].pattern);
        }
        g.spread();
        g.absorb();
        return count;
    }

    pub fn spread(g: *Lepton) void {
        g.nxt = @splat(.{ 0, 0, 0 });
        for (0..n) |i| {
            const c = g.car[i];
            if (c[0] == 0 and c[1] == 0 and c[2] == 0) continue;
            for (g3.neighbors(i)) |j| for (0..3) |k| {
                g.nxt[j][k] += c[k] / 6.0;
            };
        }
        g.car = g.nxt;
    }

    pub fn absorb(g: *Lepton) void {
        for (0..n) |i| for (0..3) |k| {
            if (g.car[i][k] < 1) continue;
            const m: u32 = @intFromFloat(@floor(g.car[i][k]));
            g.car[i][k] -= @floatFromInt(m);
            if (g.px[i].pattern & (@as(u3, 1) << @intCast(k)) != 0) {
                g.px[i].reinforce[k] += m;
            } else {
                g.px[i].conserved[k] += m;
            }
        };
    }

    pub fn carrierTotal(g: *const Lepton) f64 {
        var s: f64 = 0;
        for (g.car) |c| s += c[0] + c[1] + c[2];
        return s;
    }

    pub fn agreement(g: *const Lepton, i: usize) f64 {
        var m: u32 = 0;
        for (g3.neighbors(i)) |j| m += px.cells - @popCount(g.px[i].pattern ^ g.px[j].pattern);
        return @as(f64, @floatFromInt(m)) / (6.0 * px.cells);
    }
};

test "absorb follows the flash rule per generation" {
    const g = try std.testing.allocator.create(Lepton);
    defer std.testing.allocator.destroy(g);
    g.init(1, 0);
    g.px[0] = .{ .pattern = 0b001 };
    g.car[0] = .{ 2.5, 1.2, 0.4 };
    g.absorb();
    try std.testing.expectEqual([3]u32{ 2, 0, 0 }, g.px[0].reinforce);
    try std.testing.expectEqual([3]u32{ 0, 1, 0 }, g.px[0].conserved);
}

test "spread on wrapped edges conserves carrier" {
    const g = try std.testing.allocator.create(Lepton);
    defer std.testing.allocator.destroy(g);
    g.car = @splat(.{ 0, 0, 0 });
    g.car[0] = .{ 6, 3, 0 };
    g.spread();
    try std.testing.expectApproxEqAbs(@as(f64, 9), g.carrierTotal(), 1e-9);
}
