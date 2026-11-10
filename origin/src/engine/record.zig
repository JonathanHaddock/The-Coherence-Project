//! Data output for engine runs. One run = one folder:
//!   meta.json    settings, seed, rule choices in force
//!   series.csv   per-sample totals: flashing, agreement, carrier, memory, fill per position
//!   shells.csv   per window, per distance shell: flash rate, agreement, carrier
//!   gaps.csv     ticks between successive flashes of the same pixel, with hazard
//!                h(k) = P(flash at gap k | none before k); constant h = constant chance
//!   slice.csv    final z = side/2 slice, pattern per pixel (48 x 48)
//! Works on any grid that has px, fired, agreement(i) and either carrier or car.

const std = @import("std");
const px = @import("pixel.zig");
const g3 = @import("grid3.zig");

pub const n = g3.n;
pub const side = g3.side;
pub const bins = side / 2;
pub const gap_len = 256;

pub const Meta = struct {
    name: []const u8,
    mode: []const u8,
    display: []const u8,
    update: []const u8,
    core: u32,
    gravity: bool,
    seed: u64,
    ticks: i64,
    every: i64,
    rules: []const u8,
};

fn carrierAt(g: anytype, i: usize) f64 {
    const T = @TypeOf(g.*);
    if (@hasField(T, "car")) {
        var s: f64 = 0;
        for (g.car[i]) |v| s += v;
        return s;
    }
    return g.carrier[i];
}

pub fn run(io: std.Io, gpa: std.mem.Allocator, g: anytype, meta: Meta, out_root: []const u8) ![]const u8 {
    const dir = try std.fmt.allocPrint(gpa, "{s}/{s}", .{ out_root, meta.name });
    try std.Io.Dir.cwd().createDirPath(io, dir);

    var series: std.Io.Writer.Allocating = .init(gpa);
    defer series.deinit();
    var shells: std.Io.Writer.Allocating = .init(gpa);
    defer shells.deinit();
    try series.writer.print("tick,flashes,flashing,agreement,carrier,memory,filled0,filled1,filled2\n", .{});
    try shells.writer.print("tick_from,tick_to,dist,pixels,flash_rate,agreement,carrier\n", .{});

    const last = try gpa.alloc(i64, n);
    defer gpa.free(last);
    @memset(last, -1);
    var gaps: [gap_len]u64 = @splat(0);

    var shell_of: [n]u8 = undefined;
    var cnt: [bins]f64 = @splat(0);
    for (0..n) |i| {
        const b: usize = @intFromFloat(@floor(g3.radius(i)));
        shell_of[i] = if (b < bins) @intCast(b) else 255;
        if (b < bins) cnt[b] += 1;
    }
    var rate: [bins]f64 = @splat(0);
    var agr: [bins]f64 = @splat(0);
    var car: [bins]f64 = @splat(0);
    var w: f64 = 0;
    var win_from: i64 = 0;

    const centre = g3.index(side / 2, side / 2, side / 2);
    var t: i64 = 0;
    while (t < meta.ticks) : (t += 1) {
        const f = g.tick(t, if (t == 0) centre else null);
        for (0..n) |i| {
            if (!g.fired[i]) continue;
            if (last[i] >= 0) gaps[@min(@as(usize, @intCast(t - last[i])), gap_len - 1)] += 1;
            last[i] = t;
        }
        // shell window: every tick
        w += 1;
        for (0..n) |i| {
            const b = shell_of[i];
            if (b == 255) continue;
            if (g.fired[i]) rate[b] += 1;
            agr[b] += g.agreement(i);
            car[b] += carrierAt(g, i);
        }
        const end_of_window = @mod(t + 1, meta.every) == 0 or t == meta.ticks - 1;
        if (@mod(t, meta.every) == 0 or t == meta.ticks - 1) {
            var a: f64 = 0;
            var c: f64 = 0;
            var mem: u64 = 0;
            var fill: [3]u64 = .{ 0, 0, 0 };
            for (0..n) |i| {
                a += g.agreement(i);
                c += carrierAt(g, i);
                mem += g.px[i].memoryTotal();
                for (0..3) |k| fill[k] += (g.px[i].pattern >> @intCast(k)) & 1;
            }
            const nf: f64 = n;
            try series.writer.print("{d},{d},{d:.6},{d:.6},{d:.4},{d},{d:.6},{d:.6},{d:.6}\n", .{
                t, f, @as(f64, @floatFromInt(f)) / nf, a / nf, c, mem,
                @as(f64, @floatFromInt(fill[0])) / nf, @as(f64, @floatFromInt(fill[1])) / nf, @as(f64, @floatFromInt(fill[2])) / nf,
            });
        }
        if (end_of_window) {
            for (1..bins) |b| {
                try shells.writer.print("{d},{d},{d},{d},{d:.6},{d:.6},{d:.6}\n", .{
                    win_from, t, b, @as(u64, @intFromFloat(cnt[b])), rate[b] / (cnt[b] * w), agr[b] / (cnt[b] * w), car[b] / (cnt[b] * w),
                });
            }
            rate = @splat(0);
            agr = @splat(0);
            car = @splat(0);
            w = 0;
            win_from = t + 1;
        }
    }

    var gw: std.Io.Writer.Allocating = .init(gpa);
    defer gw.deinit();
    try gw.writer.print("gap,count,hazard\n", .{});
    var remaining: u64 = 0;
    for (gaps) |v| remaining += v;
    for (1..gap_len) |k| {
        if (remaining == 0) break;
        const h = @as(f64, @floatFromInt(gaps[k])) / @as(f64, @floatFromInt(remaining));
        try gw.writer.print("{d}{s},{d},{d:.6}\n", .{ k, if (k == gap_len - 1) "+" else "", gaps[k], h });
        remaining -= gaps[k];
    }

    var sl: std.Io.Writer.Allocating = .init(gpa);
    defer sl.deinit();
    for (0..side) |y| {
        for (0..side) |x| {
            try sl.writer.print("{s}{d}", .{ if (x == 0) "" else ",", g.px[g3.index(x, y, side / 2)].pattern });
        }
        try sl.writer.print("\n", .{});
    }

    var mj: std.Io.Writer.Allocating = .init(gpa);
    defer mj.deinit();
    try mj.writer.print(
        \\{{
        \\  "name": "{s}",
        \\  "mode": "{s}",
        \\  "display": "{s}",
        \\  "update": "{s}",
        \\  "core": {d},
        \\  "gravity": {},
        \\  "seed": {d},
        \\  "ticks": {d},
        \\  "every": {d},
        \\  "lattice": "{d}^3, 6 neighbors",
        \\  "rules": "{s}",
        \\  "files": ["series.csv", "shells.csv", "gaps.csv", "slice.csv"]
        \\}}
        \\
    , .{ meta.name, meta.mode, meta.display, meta.update, meta.core, meta.gravity, meta.seed, meta.ticks, meta.every, side, meta.rules });

    const files = [_]struct { []const u8, []const u8 }{
        .{ "meta.json", mj.written() },
        .{ "series.csv", series.written() },
        .{ "shells.csv", shells.written() },
        .{ "gaps.csv", gw.written() },
        .{ "slice.csv", sl.written() },
    };
    for (files) |fl| {
        const p = try std.fmt.allocPrint(gpa, "{s}/{s}", .{ dir, fl[0] });
        defer gpa.free(p);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = p, .data = fl[1] });
    }
    return dir;
}

/// CONTROL, not part of the engine: every pixel flashes with a fixed chance p
/// per tick (seeded, deterministic). Reference for a true constant hazard.
pub const Control = struct {
    px: [n]px.Pixel,
    fired: [n]bool,
    carrier: [n]f64,
    s: u64,
    p: f64,

    pub fn init(c: *Control, seed: u64, p: f64) void {
        c.s = seed;
        c.p = p;
        c.carrier = @splat(0);
        c.fired = @splat(false);
        for (&c.px) |*q| q.* = .{ .pattern = @truncate(c.next()) };
    }

    fn next(c: *Control) u64 {
        c.s ^= c.s << 13;
        c.s ^= c.s >> 7;
        c.s ^= c.s << 17;
        return c.s;
    }

    pub fn tick(c: *Control, t: i64, kick: ?usize) u32 {
        _ = t;
        _ = kick;
        var count: u32 = 0;
        for (0..n) |i| {
            const u = @as(f64, @floatFromInt(c.next() >> 11)) / 9007199254740992.0;
            c.fired[i] = u < c.p;
            if (c.fired[i]) count += 1;
        }
        return count;
    }

    pub fn agreement(c: *const Control, i: usize) f64 {
        var m: u32 = 0;
        for (g3.neighbors(i)) |j| m += px.cells - @popCount(c.px[i].pattern ^ c.px[j].pattern);
        return @as(f64, @floatFromInt(m)) / (6.0 * px.cells);
    }
};
