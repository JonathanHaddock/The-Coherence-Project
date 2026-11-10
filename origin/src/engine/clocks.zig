//! Per-region clocks (section 11; Witten et al. 2022-23: time only relative to a clock).
//!
//! No global time is read off the grid. The grid is cut into 8x8 regions, and
//! each region keeps two clocks:
//!   raw    = number of pixel flashes in the region
//!   merged = flashes where coherent pixels flashing together count as one tick
//!            (section 11: "Coherent pixels flash in step and count as one tick").
//!            Coherent = adjacent in the region, flashed on the same step, and now
//!            showing the same pattern. Each such connected group is one tick.
//! Each region also has a coherence: the mean fraction of matching cells across
//! neighbor bonds inside it.
//! Section 11's claim, as a test: across regions, higher coherence goes with a
//! slower clock (negative correlation), without that being written into the rules.

const std = @import("std");
const px = @import("pixel.zig");

pub const block = 8;
pub const per_side = px.side / block;
pub const regions = per_side * per_side;

pub fn regionOf(i: usize) usize {
    return (i / px.side / block) * per_side + (i % px.side) / block;
}

fn sameRegion(a: usize, b: usize) bool {
    return regionOf(a) == regionOf(b);
}

fn find(parent: []u16, x: u16) u16 {
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

pub const Window = struct {
    raw: [regions]u64 = @splat(0),
    merged: [regions]u64 = @splat(0),
    coherence: [regions]f64 = @splat(0),
    ticks: u64 = 0,

    /// Call after each grid tick.
    pub fn record(w: *Window, g: *const px.Grid) void {
        var parent: [px.n]u16 = undefined;
        for (0..px.n) |i| parent[i] = @intCast(i);
        for (0..px.n) |i| {
            if (!g.fired[i]) continue;
            w.raw[regionOf(i)] += 1;
            const nb = px.Grid.neighbors(i);
            for ([_]usize{ nb[0], nb[2] }) |j| {
                if (!g.fired[j] or !sameRegion(i, j)) continue;
                if (g.px[i].pattern != g.px[j].pattern) continue;
                const a = find(&parent, @intCast(i));
                const b = find(&parent, @intCast(j));
                if (a != b) parent[a] = b;
            }
        }
        for (0..px.n) |i| {
            if (g.fired[i] and find(&parent, @intCast(i)) == i) w.merged[regionOf(i)] += 1;
        }

        var match: [regions]u64 = @splat(0);
        var bonds: [regions]u64 = @splat(0);
        for (0..px.n) |i| {
            const nb = px.Grid.neighbors(i);
            for ([_]usize{ nb[0], nb[2] }) |j| {
                if (!sameRegion(i, j)) continue;
                const r = regionOf(i);
                match[r] += px.cells - @popCount(g.px[i].pattern ^ g.px[j].pattern);
                bonds[r] += px.cells;
            }
        }
        for (0..regions) |r| {
            w.coherence[r] += @as(f64, @floatFromInt(match[r])) / @as(f64, @floatFromInt(bonds[r]));
        }
        w.ticks += 1;
    }

    pub fn meanCoherence(w: *const Window, r: usize) f64 {
        return w.coherence[r] / @as(f64, @floatFromInt(@max(w.ticks, 1)));
    }
};

/// Pearson correlation; null when either side has no spread.
pub fn pearson(x: []const f64, y: []const f64) ?f64 {
    const k: f64 = @floatFromInt(x.len);
    var mx: f64 = 0;
    var my: f64 = 0;
    for (x, y) |a, b| {
        mx += a;
        my += b;
    }
    mx /= k;
    my /= k;
    var sxy: f64 = 0;
    var sxx: f64 = 0;
    var syy: f64 = 0;
    for (x, y) |a, b| {
        sxy += (a - mx) * (b - my);
        sxx += (a - mx) * (a - mx);
        syy += (b - my) * (b - my);
    }
    if (sxx < 1e-12 or syy < 1e-12) return null;
    return sxy / @sqrt(sxx * syy);
}

pub const Summary = struct {
    r_raw: ?f64,
    r_merged: ?f64,
    mean_coherence: f64,
    mean_raw: f64,
    mean_merged: f64,
};

pub fn summarize(w: *const Window) Summary {
    var coh: [regions]f64 = undefined;
    var raw: [regions]f64 = undefined;
    var mer: [regions]f64 = undefined;
    var sc: f64 = 0;
    var sr: f64 = 0;
    var sm: f64 = 0;
    const t: f64 = @floatFromInt(@max(w.ticks, 1));
    for (0..regions) |r| {
        coh[r] = w.meanCoherence(r);
        raw[r] = @as(f64, @floatFromInt(w.raw[r])) / t;
        mer[r] = @as(f64, @floatFromInt(w.merged[r])) / t;
        sc += coh[r];
        sr += raw[r];
        sm += mer[r];
    }
    const k: f64 = regions;
    return .{
        .r_raw = pearson(&coh, &raw),
        .r_merged = pearson(&coh, &mer),
        .mean_coherence = sc / k,
        .mean_raw = sr / k,
        .mean_merged = sm / k,
    };
}

test "pearson sign" {
    try std.testing.expect(pearson(&.{ 1, 2, 3 }, &.{ 3, 2, 1 }).? < -0.99);
    try std.testing.expect(pearson(&.{ 1, 1, 1 }, &.{ 3, 2, 1 }) == null);
}

test "merged clock counts a coherent block as one tick" {
    var g = px.Grid.initWith(.{});
    for (&g.px) |*p| p.pattern = 0b101;
    g.fired = @splat(false);
    for (0..block) |y| for (0..block) |x| {
        g.fired[y * px.side + x] = true;
    };
    var w: Window = .{};
    w.record(&g);
    try std.testing.expectEqual(@as(u64, 64), w.raw[0]);
    try std.testing.expectEqual(@as(u64, 1), w.merged[0]);
}
