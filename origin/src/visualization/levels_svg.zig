const std = @import("std");
const levels = @import("../analysis/levels.zig");

const width = 1000.0;
const height = 520.0;
const left = 70.0;
const right = 30.0;
const top = 60.0;
const bottom = 60.0;

fn frame(w: *std.Io.Writer, title: []const u8, x_label: []const u8, y_label: []const u8) !void {
    try w.print(
        \\<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {d} {d}" font-family="sans-serif" font-size="13">
        \\<rect width="100%" height="100%" fill="white"/>
        \\<text x="{d}" y="30" font-size="17" font-weight="600">{s}</text>
        \\<line x1="{d}" y1="{d}" x2="{d}" y2="{d}" stroke="#333"/>
        \\<line x1="{d}" y1="{d}" x2="{d}" y2="{d}" stroke="#333"/>
        \\<text x="{d}" y="{d}" text-anchor="middle">{s}</text>
        \\<text x="18" y="{d}" transform="rotate(-90 18 {d})" text-anchor="middle">{s}</text>
        \\
    , .{
        width,                       height,                 left,              title,
        left,                        height - bottom,        width - right,     height - bottom,
        left,                        top,                    left,              height - bottom,
        (left + width - right) / 2,  height - 18,            x_label,           (top + height - bottom) / 2,
        (top + height - bottom) / 2, y_label,
    });
}

/// Orbit signal with a marker at every log(prime power). Caller frees.
pub fn orbit(gpa: std.mem.Allocator, title: []const u8, x_lo: f64, x_hi: f64, s: []const f64) ![]u8 {
    var out: std.Io.Writer.Allocating = .init(gpa);
    errdefer out.deinit();
    const w = &out.writer;
    try frame(w, title, "loop length", "strength (down = dip)");
    const pw = width - left - right;
    const ph = height - top - bottom;
    var lo: f64 = 0;
    var hi: f64 = 0;
    for (s) |v| {
        lo = @min(lo, v);
        hi = @max(hi, v);
    }
    const X = struct {
        fn f(x: f64, a: f64, b: f64, pw_: f64) f64 {
            return left + pw_ * (x - a) / (b - a);
        }
    };
    // Prime-power markers.
    var q: u32 = 2;
    while (@log(@as(f64, @floatFromInt(q))) < x_hi) : (q += 1) {
        const pp = levels.primePower(q) orelse continue;
        const x = X.f(@log(@as(f64, @floatFromInt(q))), x_lo, x_hi, pw);
        const col = if (pp.k == 1) "#d33" else "#e9a";
        try w.print("<line x1=\"{d:.1}\" y1=\"{d}\" x2=\"{d:.1}\" y2=\"{d}\" stroke=\"{s}\" stroke-width=\"1\" opacity=\"0.6\"/>\n", .{ x, top, x, height - bottom, col });
        if (pp.k == 1 and q < 30) try w.print("<text x=\"{d:.1}\" y=\"{d}\" fill=\"#d33\" text-anchor=\"middle\" font-size=\"11\">{d}</text>\n", .{ x, top - 6, q });
    }
    // Zero line.
    const y0 = top + ph * (hi - 0) / (hi - lo);
    try w.print("<line x1=\"{d}\" y1=\"{d:.1}\" x2=\"{d}\" y2=\"{d:.1}\" stroke=\"#aaa\" stroke-dasharray=\"3 3\"/>\n", .{ left, y0, width - right, y0 });
    try w.writeAll("<polyline fill=\"none\" stroke=\"#1a4d8f\" stroke-width=\"1\" points=\"");
    for (s, 0..) |v, i| {
        const x = left + pw * @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(s.len - 1));
        const y = top + ph * (hi - v) / (hi - lo);
        try w.print("{d:.1},{d:.1} ", .{ x, y });
    }
    try w.writeAll("\"/>\n");
    var x_tick: f64 = @ceil(x_lo * 2) / 2;
    while (x_tick <= x_hi) : (x_tick += 0.5) {
        try w.print("<text x=\"{d:.1}\" y=\"{d}\" text-anchor=\"middle\" font-size=\"11\">{d:.1}</text>\n", .{ X.f(x_tick, x_lo, x_hi, pw), height - bottom + 16, x_tick });
    }
    try w.print("<text x=\"{d}\" y=\"{d}\" font-size=\"11\" fill=\"#555\">red lines: log of each prime (dark) and prime powers (light)</text>\n", .{ width - right - 260, height - bottom + 34 });
    try w.writeAll("</svg>\n");
    return out.toOwnedSlice();
}

/// Spacing histogram against Poisson, GOE and GUE. Caller frees.
pub fn spacing(gpa: std.mem.Allocator, title: []const u8, hist: [30]f64) ![]u8 {
    var out: std.Io.Writer.Allocating = .init(gpa);
    errdefer out.deinit();
    const w = &out.writer;
    try frame(w, title, "gap size (1 = average gap)", "how often");
    const pw = width - left - right;
    const ph = height - top - bottom;
    const ymax = 1.1;
    for (hist, 0..) |h, i| {
        const x = left + pw * @as(f64, @floatFromInt(i)) / 30.0;
        const y = top + ph * (1 - @min(h, ymax) / ymax);
        try w.print("<rect x=\"{d:.1}\" y=\"{d:.1}\" width=\"{d:.1}\" height=\"{d:.1}\" fill=\"#c9d6ea\" stroke=\"#8aa3c8\"/>\n", .{ x, y, pw / 30.0, height - bottom - y });
    }
    const curves = .{ .{ levels.Ensemble.poisson, "#999", "random" }, .{ levels.Ensemble.goe, "#2a9d4b", "avoid" }, .{ levels.Ensemble.gue, "#d33", "avoid strongly" } };
    inline for (curves, 0..) |c, k| {
        try w.print("<polyline fill=\"none\" stroke=\"{s}\" stroke-width=\"2\" points=\"", .{c[1]});
        for (0..301) |i| {
            const s = 3.0 * @as(f64, @floatFromInt(i)) / 300.0;
            const y = top + ph * (1 - @min(levels.spacingDensity(c[0], s), ymax) / ymax);
            try w.print("{d:.1},{d:.1} ", .{ left + pw * s / 3.0, y });
        }
        try w.writeAll("\"/>\n");
        try w.print("<text x=\"{d}\" y=\"{d}\" fill=\"{s}\" font-weight=\"600\">{s}</text>\n", .{ width - right - 140, top + 20 + 20 * @as(f64, k), c[1], c[2] });
    }
    for (0..4) |i| try w.print("<text x=\"{d:.1}\" y=\"{d}\" text-anchor=\"middle\" font-size=\"11\">{d}</text>\n", .{ left + pw * @as(f64, @floatFromInt(i)) / 3.0, height - bottom + 16, i });
    try w.writeAll("</svg>\n");
    return out.toOwnedSlice();
}
