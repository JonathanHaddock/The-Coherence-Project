//! Line charts for the reactor module: flux/power profiles and transients.

const std = @import("std");

const surface = "#fcfcfb";
const ink = "#1f1f1e";
const ink_2 = "#6b6a64";
const grid_c = "#e6e5e0";
pub const blue = "#2a78d6";
pub const orange = "#eb6834";
pub const green = "#1baf7a";

pub const Series = struct {
    name: []const u8,
    color: []const u8,
    y: []const f64,
};

pub const Chart = struct {
    title: []const u8,
    subtitle: []const u8,
    x_label: []const u8,
    y_label: []const u8,
    x: []const f64,
    series: []const Series,
    marker_x: ?f64 = null, // vertical dashed line (e.g. fuel edge)
    marker_label: []const u8 = "",
    y_min: ?f64 = null,
};

fn niceStep(span: f64) f64 {
    const raw = span / 5.0;
    const mag = std.math.pow(f64, 10, @floor(std.math.log10(raw)));
    const f = raw / mag;
    const nice: f64 = if (f < 1.5) 1 else if (f < 3.5) 2 else if (f < 7.5) 5 else 10;
    return nice * mag;
}

fn num(w: *std.Io.Writer, v: f64, step: f64) !void {
    const dec: i32 = @max(0, -@as(i32, @intFromFloat(@floor(std.math.log10(step)))));
    const r = @round(v / step) * step;
    switch (dec) {
        0 => try w.print("{d:.0}", .{r}),
        1 => try w.print("{d:.1}", .{r}),
        2 => try w.print("{d:.2}", .{r}),
        else => try w.print("{d:.3}", .{r}),
    }
}

/// Caller frees.
pub fn render(gpa: std.mem.Allocator, c: Chart) ![]u8 {
    var out: std.Io.Writer.Allocating = .init(gpa);
    errdefer out.deinit();
    const w = &out.writer;

    const width = 1000.0;
    const height = 600.0;
    const x0 = 90.0;
    const x1 = width - 40;
    const y0 = 90.0;
    const y1 = height - 80;

    var xmin = c.x[0];
    var xmax = c.x[0];
    for (c.x) |v| {
        xmin = @min(xmin, v);
        xmax = @max(xmax, v);
    }
    var ymin: f64 = std.math.inf(f64);
    var ymax: f64 = -std.math.inf(f64);
    for (c.series) |s| for (s.y) |v| {
        if (!std.math.isFinite(v)) continue;
        ymin = @min(ymin, v);
        ymax = @max(ymax, v);
    };
    if (c.y_min) |m| ymin = m;
    if (ymax - ymin < 1e-12) ymax = ymin + 1;
    const ys = niceStep(ymax - ymin);
    ymin = @floor(ymin / ys) * ys;
    ymax = @ceil(ymax / ys) * ys;
    const xs = niceStep(xmax - xmin);

    const S = struct {
        a: f64,
        b: f64,
        ya: f64,
        yb: f64,
        fn x(s: @This(), v: f64) f64 {
            return x0 + (x1 - x0) * (v - s.a) / (s.b - s.a);
        }
        fn y(s: @This(), v: f64) f64 {
            return y1 - (y1 - y0) * (v - s.ya) / (s.yb - s.ya);
        }
    };
    const sc = S{ .a = xmin, .b = xmax, .ya = ymin, .yb = ymax };

    try w.print(
        \\<?xml version="1.0" encoding="UTF-8"?>
        \\<svg xmlns="http://www.w3.org/2000/svg" width="{d}" height="{d}" viewBox="0 0 {d} {d}" font-family="Helvetica, Arial, sans-serif">
        \\<rect width="100%" height="100%" fill="{s}"/>
        \\<text x="24" y="36" fill="{s}" font-size="20" font-weight="bold">{s}</text>
        \\<text x="24" y="60" fill="{s}" font-size="13">{s}</text>
        \\
    , .{ width, height, width, height, surface, ink, c.title, ink_2, c.subtitle });

    // Grid and ticks.
    var gy = ymin;
    while (gy <= ymax + ys * 0.01) : (gy += ys) {
        const py = sc.y(gy);
        try w.print("<line x1=\"{d:.1}\" y1=\"{d:.1}\" x2=\"{d:.1}\" y2=\"{d:.1}\" stroke=\"{s}\"/>\n", .{ x0, py, x1, py, grid_c });
        try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"12\" text-anchor=\"end\">", .{ x0 - 8, py + 4, ink_2 });
        try num(w, gy, ys);
        try w.writeAll("</text>\n");
    }
    var gx = @ceil(xmin / xs) * xs;
    while (gx <= xmax + xs * 0.01) : (gx += xs) {
        const px = sc.x(gx);
        try w.print("<line x1=\"{d:.1}\" y1=\"{d:.1}\" x2=\"{d:.1}\" y2=\"{d:.1}\" stroke=\"{s}\"/>\n", .{ px, y1, px, y1 + 5, ink_2 });
        try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"12\" text-anchor=\"middle\">", .{ px, y1 + 20, ink_2 });
        try num(w, gx, xs);
        try w.writeAll("</text>\n");
    }
    try w.print("<line x1=\"{d}\" y1=\"{d}\" x2=\"{d}\" y2=\"{d}\" stroke=\"{s}\"/>\n", .{ x0, y1, x1, y1, ink_2 });
    try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"13\" text-anchor=\"middle\">{s}</text>\n", .{ (x0 + x1) / 2, height - 30, ink, c.x_label });
    try w.print("<text transform=\"translate(28 {d:.1}) rotate(-90)\" fill=\"{s}\" font-size=\"13\" text-anchor=\"middle\">{s}</text>\n", .{ (y0 + y1) / 2, ink, c.y_label });

    if (c.marker_x) |mx| {
        const px = sc.x(mx);
        try w.print("<line x1=\"{d:.1}\" y1=\"{d}\" x2=\"{d:.1}\" y2=\"{d}\" stroke=\"{s}\" stroke-dasharray=\"5 4\"/>\n", .{ px, y0, px, y1, ink_2 });
        try w.print("<text x=\"{d:.1}\" y=\"{d}\" fill=\"{s}\" font-size=\"12\">{s}</text>\n", .{ px + 6, y0 + 14, ink_2, c.marker_label });
    }

    for (c.series, 0..) |s, si| {
        try w.print("<polyline fill=\"none\" stroke=\"{s}\" stroke-width=\"2.2\" points=\"", .{s.color});
        for (c.x, s.y) |xv, yv| {
            if (!std.math.isFinite(yv)) continue;
            try w.print("{d:.1},{d:.1} ", .{ sc.x(xv), sc.y(std.math.clamp(yv, ymin, ymax)) });
        }
        try w.writeAll("\"/>\n");
        const ly = y0 - 14 + 0 * @as(f64, @floatFromInt(si));
        const lx = x1 - 180.0 * @as(f64, @floatFromInt(c.series.len - si));
        try w.print("<rect x=\"{d:.1}\" y=\"{d:.1}\" width=\"14\" height=\"4\" fill=\"{s}\"/>\n", .{ lx, ly - 4, s.color });
        try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"13\">{s}</text>\n", .{ lx + 20, ly, ink, s.name });
    }

    try w.writeAll("</svg>\n");
    return out.toOwnedSlice();
}
