//! 3D lattice: same pixels and flash rule as the 2D grid, 6 face neighbors,
//! wrapping edges for the pixels.
//!
//! Carrier (provisional, RULE CHOICE 5, measurement only):
//!   When a pixel flashes, the conserved share it releases (the neutrino flash)
//!   becomes carrier at that site. Each tick every site passes its carrier
//!   evenly to its 6 neighbors: one hop per tick, the same speed as a flash.
//!   Carrier that steps off the box is lost (open edges stand in for open space;
//!   on a wrapped box it would pile up forever).
//!   The carrier does NOT act back on the pixels yet. How it should (add
//!   reinforcement? cancel memory?) is undecided. This run only asks whether
//!   spreading in 3D gives a 1/distance profile on its own.

const std = @import("std");
const px = @import("pixel.zig");

/// Set at build time: zig build -Dside=96 (default 48).
pub const side: usize = @import("build_options").side;
pub const n = side * side * side;

pub fn coords(i: usize) [3]usize {
    return .{ i % side, (i / side) % side, i / (side * side) };
}

pub fn index(x: usize, y: usize, z: usize) usize {
    return (z * side + y) * side + x;
}

pub fn neighbors(i: usize) [6]usize {
    const c = coords(i);
    const x = c[0];
    const y = c[1];
    const z = c[2];
    return .{
        index((x + 1) % side, y, z), index((x + side - 1) % side, y, z),
        index(x, (y + 1) % side, z), index(x, (y + side - 1) % side, z),
        index(x, y, (z + 1) % side), index(x, y, (z + side - 1) % side),
    };
}

/// Distance from the box centre, in cells.
pub fn radius(i: usize) f64 {
    const c = coords(i);
    var s: f64 = 0;
    for (c) |v| {
        const d = @as(f64, @floatFromInt(v)) - side / 2;
        s += d * d;
    }
    return @sqrt(s);
}

pub const Grid3 = struct {
    px: [n]px.Pixel,
    fired: [n]bool,
    carrier: [n]f64,
    next: [n]f64,
    cfg: px.Config,
    /// RULE CHOICE 6: carrier acts back on pixels (gravity feedback).
    gravity: bool,
    /// RULE 21: carrier cancels memory (build spec R-A). Not used together with gravity.
    cancel: bool,
    /// RULE 22: exclusion on the pattern (build spec R-B).
    exclusion: bool,

    pub fn init(g: *Grid3, cfg: px.Config) void {
        g.cfg = cfg;
        g.gravity = false;
        g.cancel = false;
        g.exclusion = false;
        g.fired = @splat(false);
        g.carrier = @splat(0);
        var s = cfg.seed;
        for (&g.px) |*p| {
            s ^= s << 13;
            s ^= s >> 7;
            s ^= s << 17;
            p.* = .{ .pattern = @truncate(s) };
            for (0..px.cells) |k| p.conserved[k] = @intCast((s >> @intCast(8 + 2 * k)) % 2);
        }
        switch (cfg.start) {
            .random => {},
            .core => |r| for (&g.px, 0..) |*p, i| {
                if (radius(i) <= @as(f64, @floatFromInt(r))) {
                    p.pattern = 0b111;
                    p.conserved = .{ 1, 1, 1 };
                }
            },
        }
    }

    fn fire(g: *Grid3, i: usize, t: i64) u32 {
        const released = g.px[i].flashWith(t, g.cfg.display);
        g.carrier[i] += @floatFromInt(released);
        g.fired[i] = true;
        return 1;
    }

    pub fn tick(g: *Grid3, t: i64, kick: ?usize) u32 {
        var count: u32 = 0;
        g.fired = @splat(false);
        switch (g.cfg.update) {
            .sync => {
                for (0..n) |i| g.fired[i] = (g.px[i].ready() or kick == i) and !g.blocked(i);
                for (0..n) |i| if (g.fired[i]) {
                    count += g.fire(i, t);
                };
                for (0..n) |i| {
                    if (!g.fired[i]) continue;
                    for (neighbors(i)) |j| g.px[j].receive(g.px[i].pattern);
                }
            },
            .sweep => for (0..n) |i| {
                if (!(g.px[i].ready() or kick == i)) continue;
                if (g.blocked(i)) continue;
                count += g.fire(i, t);
                for (neighbors(i)) |j| g.px[j].receive(g.px[i].pattern);
            },
        }
        g.spread();
        if (g.gravity) g.absorb() else if (g.cancel) g.cancelMemory();
        return count;
    }

    /// RULE CHOICE 6: each whole pixel's worth of carrier (3 units) at a site
    /// is taken from the field and reinforces every cell of the pattern the
    /// pixel shows now (section 6: gravity pushes the display back into the
    /// scaffold). The only number is the cell count.
    pub fn absorb(g: *Grid3) void {
        const unit: f64 = px.cells;
        for (0..n) |i| {
            if (g.carrier[i] < unit) continue;
            const k: u32 = @intFromFloat(@floor(g.carrier[i] / unit));
            g.carrier[i] -= @as(f64, @floatFromInt(k)) * unit;
            for (0..px.cells) |c| g.px[i].reinforce[c] += k;
        }
    }

    /// RULE 22: a flash may not display a pattern any neighbour is showing.
    /// A blocked pixel waits: no flash, pattern and memory kept.
    pub fn blocked(g: *const Grid3, i: usize) bool {
        if (!g.exclusion) return false;
        const next = g.px[i].nextPattern(g.cfg.display);
        for (neighbors(i)) |j| if (g.px[j].pattern == next) return true;
        return false;
    }

    /// RULE 21: each whole pixel's worth of carrier (3 units) at a site cancels
    /// one conserved unit on each cell that holds one. One carrier unit is used
    /// up per memory unit cancelled. The only number is the cell count.
    pub fn cancelMemory(g: *Grid3) void {
        const unit: f64 = px.cells;
        for (0..n) |i| {
            if (g.carrier[i] < unit) continue;
            const k: u32 = @intFromFloat(@floor(g.carrier[i] / unit));
            for (0..px.cells) |c| {
                const m = @min(k, g.px[i].conserved[c]);
                g.px[i].conserved[c] -= m;
                g.carrier[i] -= @floatFromInt(m);
            }
        }
    }

    /// Fraction of matching cells between pixel i and its 6 neighbors.
    pub fn agreement(g: *const Grid3, i: usize) f64 {
        var m: u32 = 0;
        for (neighbors(i)) |j| m += px.cells - @popCount(g.px[i].pattern ^ g.px[j].pattern);
        return @as(f64, @floatFromInt(m)) / (6.0 * px.cells);
    }

    /// One hop: each site hands 1/6 of its carrier to each face neighbor.
    /// Shares that would cross the box edge are lost.
    pub fn spread(g: *Grid3) void {
        g.next = @splat(0);
        for (0..n) |i| {
            const q = g.carrier[i];
            if (q == 0) continue;
            const share = q / 6.0;
            const c = coords(i);
            if (c[0] + 1 < side) g.next[i + 1] += share;
            if (c[0] > 0) g.next[i - 1] += share;
            if (c[1] + 1 < side) g.next[i + side] += share;
            if (c[1] > 0) g.next[i - side] += share;
            if (c[2] + 1 < side) g.next[i + side * side] += share;
            if (c[2] > 0) g.next[i - side * side] += share;
        }
        g.carrier = g.next;
    }
};

test "neighbors wrap and are distinct" {
    const nb = neighbors(index(0, 0, 0));
    try std.testing.expectEqual(index(side - 1, 0, 0), nb[1]);
    for (nb, 0..) |a, k| for (nb[k + 1 ..]) |b| try std.testing.expect(a != b);
}

test "spread conserves carrier away from edges" {
    const g = try std.testing.allocator.create(Grid3);
    defer std.testing.allocator.destroy(g);
    g.carrier = @splat(0);
    g.carrier[index(side / 2, side / 2, side / 2)] = 6;
    g.spread();
    var total: f64 = 0;
    for (g.carrier) |v| total += v;
    try std.testing.expectApproxEqAbs(@as(f64, 6), total, 1e-9);
}

test "point source in 3D gives roughly 1/distance" {
    // Steady state of a constant source at the centre, no pixels involved.
    const g = try std.testing.allocator.create(Grid3);
    defer std.testing.allocator.destroy(g);
    g.carrier = @splat(0);
    var avg: [side]f64 = @splat(0);
    const c = index(side / 2, side / 2, side / 2);
    for (0..3000) |t| {
        g.carrier[c] += 1;
        g.spread();
        if (t >= 2000) for (0..side / 2) |d| {
            avg[d] += g.carrier[index(side / 2 + d, side / 2, side / 2)];
        };
    }
    // field(4)*4 vs field(8)*8: equal for exact 1/d (edge loss lowers the far one a bit)
    const a = avg[4] * 4;
    const b = avg[8] * 8;
    try std.testing.expect(b / a > 0.7 and b / a < 1.05);
}

test "rule 22: a flash into a neighbour's pattern waits" {
    const g = try std.testing.allocator.create(Grid3);
    defer std.testing.allocator.destroy(g);
    g.init(.{ .display = .hold, .update = .sync });
    g.exclusion = true;
    const i = index(5, 5, 5);
    g.px[i].conserved = .{ 1, 1, 1 }; // ready
    for (neighbors(i)) |j| g.px[j].pattern = g.px[i].pattern ^ 1;
    try std.testing.expect(!g.blocked(i));
    g.px[neighbors(i)[3]].pattern = g.px[i].pattern; // hold shows the same pattern
    try std.testing.expect(g.blocked(i));
}

test "rule 21: carrier cancels memory one for one" {
    const g = try std.testing.allocator.create(Grid3);
    defer std.testing.allocator.destroy(g);
    g.init(.{});
    g.carrier = @splat(0);
    g.px[0].conserved = .{ 2, 0, 1 };
    g.carrier[0] = 7.5; // two whole pixels' worth
    g.cancelMemory();
    try std.testing.expectEqual([3]u32{ 0, 0, 0 }, g.px[0].conserved);
    try std.testing.expectApproxEqAbs(@as(f64, 4.5), g.carrier[0], 1e-12); // 3 units used
}

test "absorb turns whole pixels of carrier into reinforcement" {
    const g = try std.testing.allocator.create(Grid3);
    defer std.testing.allocator.destroy(g);
    g.init(.{});
    g.carrier = @splat(0);
    g.px[0].reinforce = .{ 0, 0, 0 };
    g.carrier[0] = 7.5;
    g.absorb();
    try std.testing.expectEqual([3]u32{ 2, 2, 2 }, g.px[0].reinforce);
    try std.testing.expectApproxEqAbs(@as(f64, 1.5), g.carrier[0], 1e-12);
}
