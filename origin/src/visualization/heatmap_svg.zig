//! Heat maps of a 2D quarter-core: one panel per field, rods outlined.

const std = @import("std");
const d2 = @import("../reactor/diffusion2d.zig");

const surface = "#fcfcfb";
const ink = "#1f1f1e";
const ink_2 = "#6b6a64";

pub const Panel = struct { title: []const u8, field: []const f64 };

// Sequential scale, dark blue -> teal -> yellow.
const stops = [_][3]f64{
    .{ 0x1b, 0x1f, 0x4b },
    .{ 0x2a, 0x78, 0xd6 },
    .{ 0x1b, 0xaf, 0x7a },
    .{ 0xf2, 0xc9, 0x4c },
    .{ 0xfb, 0xf4, 0xd8 },
};

fn color(t_in: f64) [3]u8 {
    const t = std.math.clamp(t_in, 0, 1) * @as(f64, stops.len - 1);
    const i: usize = @min(stops.len - 2, @as(usize, @intFromFloat(@floor(t))));
    const f = t - @as(f64, @floatFromInt(i));
    var out: [3]u8 = undefined;
    for (0..3) |c| out[c] = @intFromFloat(@round(stops[i][c] + (stops[i + 1][c] - stops[i][c]) * f));
    return out;
}

/// Caller frees.
pub fn render(gpa: std.mem.Allocator, r: d2.Result, title: []const u8, subtitle: []const u8, panels: []const Panel) ![]u8 {
    var out: std.Io.Writer.Allocating = .init(gpa);
    errdefer out.deinit();
    const w = &out.writer;

    const side = 420.0;
    const gap = 70.0;
    const left = 40.0;
    const top = 100.0;
    const np: f64 = @floatFromInt(panels.len);
    const width = left * 2 + side * np + gap * (np - 1);
    const height = top + side + 90;
    const n = r.n;
    const px = side / @as(f64, @floatFromInt(n));

    try w.print(
        \\<?xml version="1.0" encoding="UTF-8"?>
        \\<svg xmlns="http://www.w3.org/2000/svg" width="{d}" height="{d}" viewBox="0 0 {d} {d}" font-family="Helvetica, Arial, sans-serif">
        \\<rect width="100%" height="100%" fill="{s}"/>
        \\<text x="24" y="36" fill="{s}" font-size="20" font-weight="bold">{s}</text>
        \\<text x="24" y="60" fill="{s}" font-size="13">{s}</text>
        \\
    , .{ width, height, width, height, surface, ink, title, ink_2, subtitle });

    for (panels, 0..) |p, pi| {
        const ox = left + @as(f64, @floatFromInt(pi)) * (side + gap);
        var vmax: f64 = 0;
        for (p.field) |v| vmax = @max(vmax, v);
        try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"14\" font-weight=\"bold\">{s}</text>\n", .{ ox, top - 12, ink, p.title });
        try w.print("<g shape-rendering=\"crispEdges\">\n", .{});
        for (0..n) |j| for (0..n) |i| {
            const c = j * n + i;
            const col = color(p.field[c] / vmax);
            // y grows upward in physics, downward in SVG.
            const x = ox + @as(f64, @floatFromInt(i)) * px;
            const y = top + side - @as(f64, @floatFromInt(j + 1)) * px;
            try w.print("<rect x=\"{d:.2}\" y=\"{d:.2}\" width=\"{d:.2}\" height=\"{d:.2}\" fill=\"#{x:0>2}{x:0>2}{x:0>2}\"/>", .{ x, y, px + 0.3, px + 0.3, col[0], col[1], col[2] });
        };
        try w.writeAll("</g>\n");
        // Outline rods and the fuel boundary.
        for (0..n) |j| for (0..n) |i| {
            const c = j * n + i;
            const x = ox + @as(f64, @floatFromInt(i)) * px;
            const y = top + side - @as(f64, @floatFromInt(j + 1)) * px;
            const k = r.kind[c];
            if (k == .rod) try w.print("<rect x=\"{d:.2}\" y=\"{d:.2}\" width=\"{d:.2}\" height=\"{d:.2}\" fill=\"none\" stroke=\"#eb6834\" stroke-width=\"1\"/>", .{ x, y, px, px });
            const east = i + 1 < n and (r.kind[c + 1] == .reflector) != (k == .reflector);
            const north = j + 1 < n and (r.kind[c + n] == .reflector) != (k == .reflector);
            if (east) try w.print("<line x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" stroke=\"#ffffff\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"/>", .{ x + px, y, x + px, y + px });
            if (north) try w.print("<line x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" stroke=\"#ffffff\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"/>", .{ x, y, x + px, y });
        };
        try w.writeAll("\n");
        // Axis labels.
        const extent = r.h * @as(f64, @floatFromInt(n));
        try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"12\">0</text>\n", .{ ox, top + side + 16, ink_2 });
        try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"12\" text-anchor=\"end\">{d:.0} cm</text>\n", .{ ox + side, top + side + 16, ink_2, extent });
        try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"12\">peak {d:.2}</text>\n", .{ ox, top + side + 36, ink_2, vmax });
        // Colour bar.
        const bx = ox + side - 160;
        for (0..40) |s| {
            const col = color(@as(f64, @floatFromInt(s)) / 39.0);
            try w.print("<rect x=\"{d:.1}\" y=\"{d:.1}\" width=\"4.2\" height=\"10\" fill=\"#{x:0>2}{x:0>2}{x:0>2}\"/>", .{ bx + @as(f64, @floatFromInt(s)) * 4, top + side + 27, col[0], col[1], col[2] });
        }
        try w.print("\n<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"11\">0</text><text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"11\" text-anchor=\"end\">max</text>\n", .{ bx - 10, top + side + 36, ink_2, bx + 172, top + side + 36, ink_2 });
    }
    try w.print("<text x=\"24\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"12\">Quarter core: centre at bottom-left. Orange squares: control rods. Dashed white: fuel / reflector boundary.</text>\n", .{ height - 14, ink_2 });
    try w.writeAll("</svg>\n");
    return out.toOwnedSlice();
}
