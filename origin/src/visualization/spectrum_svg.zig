const std = @import("std");
const spectrum = @import("../analysis/spectrum.zig");

pub const Label = struct {
    name: []const u8,
    mass: f64,
};

const width = 1000.0;
const height = 600.0;
const left = 80.0;
const right = 30.0;
const top = 60.0;
const bottom = 70.0;

/// Render a dimuon mass spectrum on log-log axes, with labelled peaks.
/// Caller frees the returned SVG.
pub fn render(gpa: std.mem.Allocator, title: []const u8, h: spectrum.LogHistogram, labels: []const Label) ![]u8 {
    var out: std.Io.Writer.Allocating = .init(gpa);
    errdefer out.deinit();
    const w = &out.writer;

    const plot_w = width - left - right;
    const plot_h = height - top - bottom;
    const log_max = @log10(@as(f64, @floatFromInt(@max(h.max(), 10))));

    const Scale = struct {
        hist: spectrum.LogHistogram,
        pw: f64,
        ph: f64,
        ymax: f64,
        fn x(s: @This(), mass: f64) f64 {
            return left + s.pw * @log(mass / s.hist.lo) / @log(s.hist.hi / s.hist.lo);
        }
        fn y(s: @This(), count: u32) f64 {
            // log10(count + 1) so empty bins sit on the axis.
            return top + s.ph * (1.0 - @log10(@as(f64, @floatFromInt(count)) + 1.0) / s.ymax);
        }
    };
    const s: Scale = .{ .hist = h, .pw = plot_w, .ph = plot_h, .ymax = log_max };

    try w.print(
        \\<?xml version="1.0" encoding="UTF-8"?>
        \\<svg xmlns="http://www.w3.org/2000/svg" width="{d}" height="{d}" viewBox="0 0 {d} {d}" font-family="monospace">
        \\<rect width="100%" height="100%" fill="#080d18"/>
        \\<text x="{d}" y="34" fill="#ffffff" font-size="20" text-anchor="middle">{s}</text>
        \\
    , .{ width, height, width, height, width / 2, title });

    // Decade grid lines on both axes.
    var decade: f64 = 1;
    while (decade <= h.hi) : (decade *= 10) {
        if (decade < h.lo) continue;
        const x = s.x(decade);
        try w.print("<line x1=\"{d:.1}\" y1=\"{d}\" x2=\"{d:.1}\" y2=\"{d}\" stroke=\"#26364a\"/>\n", .{ x, top, x, top + plot_h });
        try w.print("<text x=\"{d:.1}\" y=\"{d}\" fill=\"#8ca5c5\" font-size=\"13\" text-anchor=\"middle\">{d}</text>\n", .{ x, top + plot_h + 20, decade });
    }
    var power: u32 = 1;
    while (@as(f64, @floatFromInt(power)) <= log_max) : (power += 1) {
        const count = std.math.pow(u32, 10, power);
        const y = s.y(count - 1);
        try w.print("<line x1=\"{d}\" y1=\"{d:.1}\" x2=\"{d}\" y2=\"{d:.1}\" stroke=\"#26364a\"/>\n", .{ left, y, left + plot_w, y });
        try w.print("<text x=\"{d}\" y=\"{d:.1}\" fill=\"#8ca5c5\" font-size=\"13\" text-anchor=\"end\">{d}</text>\n", .{ left - 8, y + 4, count });
    }

    // Spectrum as a step line.
    try w.print("<path fill=\"none\" stroke=\"#42a5f5\" stroke-width=\"1.5\" d=\"M{d:.1} {d:.1}", .{ s.x(h.lo), s.y(0) });
    for (h.counts, 0..) |count, i| {
        const y = s.y(count);
        try w.print(" L{d:.1} {d:.1} L{d:.1} {d:.1}", .{ s.x(h.edge(i)), y, s.x(h.edge(i + 1)), y });
    }
    try w.print("\"/>\n", .{});

    for (labels, 0..) |label, i| {
        const x = s.x(label.mass);
        // Alternate label rows so neighbouring peaks (J/psi, psi(2S)) do not overlap.
        const label_y = top + 18 + @as(f64, @floatFromInt(i % 2)) * 18;
        try w.print("<line x1=\"{d:.1}\" y1=\"{d}\" x2=\"{d:.1}\" y2=\"{d}\" stroke=\"#ffca28\" stroke-dasharray=\"3 4\"/>\n", .{ x, label_y + 6, x, top + plot_h });
        try w.print("<text x=\"{d:.1}\" y=\"{d}\" fill=\"#ffca28\" font-size=\"13\" text-anchor=\"middle\">{s}</text>\n", .{ x, label_y, label.name });
    }

    try w.print(
        \\<rect x="{d}" y="{d}" width="{d}" height="{d}" fill="none" stroke="#35465d"/>
        \\<text x="{d}" y="{d}" fill="#8ca5c5" font-size="14" text-anchor="middle">dimuon invariant mass (GeV)</text>
        \\<text x="20" y="{d}" fill="#8ca5c5" font-size="14" text-anchor="middle" transform="rotate(-90 20 {d})">events per bin</text>
        \\</svg>
        \\
    , .{ left, top, plot_w, plot_h, left + plot_w / 2, height - 22, top + plot_h / 2, top + plot_h / 2 });

    return out.toOwnedSlice();
}
