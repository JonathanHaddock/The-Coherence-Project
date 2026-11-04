const std = @import("std");
const weak = @import("../analysis/weak.zig");
const labels = @import("labels.zig");

const surface = "#fcfcfb";
const ink = "#1f1f1e";
const ink_2 = "#6b6a64";
const grid = "#e6e5e0";
const curve = "#2a78d6";
const rule = "#eb6834";
const meas = "#1baf7a";

/// Charged-lepton projection share against sin^2(theta_W), with the 1/3
/// rule and the three measured definitions marked. Caller frees.
pub fn render(gpa: std.mem.Allocator) ![]u8 {
    var out: std.Io.Writer.Allocating = .init(gpa);
    errdefer out.deinit();
    const w = &out.writer;

    const width = 1000.0;
    const height = 600.0;
    const x0 = 90.0;
    const x1 = width - 40;
    const y0 = 80.0;
    const y1 = height - 90;
    const s_lo = 0.215;
    const s_hi = 0.245;
    const f_lo = 0.30;
    const f_hi = 0.36;
    const Sc = struct {
        fn x(s: f64) f64 {
            return x0 + (x1 - x0) * (s - s_lo) / (s_hi - s_lo);
        }
        fn y(f: f64) f64 {
            return y1 - (y1 - y0) * (f - f_lo) / (f_hi - f_lo);
        }
    };

    var placer = labels.Placer.init(gpa, .{ .x0 = 8, .y0 = 50, .x1 = width - 8, .y1 = height - 30 });
    defer placer.deinit();

    const title = "Charged-lepton projection vs weak mixing angle";
    try w.print(
        \\<?xml version="1.0" encoding="UTF-8"?>
        \\<svg xmlns="http://www.w3.org/2000/svg" width="{d}" height="{d}" viewBox="0 0 {d} {d}" font-family="Helvetica, Arial, sans-serif">
        \\<rect width="100%" height="100%" fill="{s}"/>
        \\<text x="24" y="38" fill="{s}" font-size="20" font-weight="bold">{s}</text>
        \\
    , .{ width, height, width, height, surface, ink, title });
    try placer.reserveText(title, 20, 24, 38, .start);

    // Grid and ticks.
    var s: f64 = 0.215;
    while (s <= s_hi + 1e-9) : (s += 0.005) {
        try w.print("<line x1=\"{d:.1}\" y1=\"{d}\" x2=\"{d:.1}\" y2=\"{d}\" stroke=\"{s}\"/>\n", .{ Sc.x(s), y0, Sc.x(s), y1, grid });
        var buf: [12]u8 = undefined;
        const t = std.fmt.bufPrint(&buf, "{d:.3}", .{s}) catch "";
        try w.print("<text x=\"{d:.1}\" y=\"{d}\" fill=\"{s}\" font-size=\"12\" text-anchor=\"middle\">{s}</text>\n", .{ Sc.x(s), y1 + 18, ink_2, t });
        try placer.reserveText(t, 12, Sc.x(s), y1 + 18, .middle);
    }
    var f: f64 = 0.30;
    while (f <= f_hi + 1e-9) : (f += 0.01) {
        try w.print("<line x1=\"{d}\" y1=\"{d:.1}\" x2=\"{d}\" y2=\"{d:.1}\" stroke=\"{s}\"/>\n", .{ x0, Sc.y(f), x1, Sc.y(f), grid });
        var buf: [12]u8 = undefined;
        const t = std.fmt.bufPrint(&buf, "{d:.2}", .{f}) catch "";
        try w.print("<text x=\"{d}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"12\" text-anchor=\"end\">{s}</text>\n", .{ x0 - 8, Sc.y(f) + 4, ink_2, t });
        try placer.reserveText(t, 12, x0 - 8, Sc.y(f) + 4, .end);
    }
    const xlabel = "sin^2(theta_W)";
    try w.print("<text x=\"{d:.1}\" y=\"{d}\" fill=\"{s}\" font-size=\"13\" text-anchor=\"middle\">{s}</text>\n", .{ (x0 + x1) / 2, y1 + 42, ink_2, xlabel });
    try placer.reserveText(xlabel, 13, (x0 + x1) / 2, y1 + 42, .middle);
    try w.print("<text x=\"22\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"13\" text-anchor=\"middle\" transform=\"rotate(-90 22 {d:.1})\">charged-lepton off-axis share</text>\n", .{ (y0 + y1) / 2, ink_2, (y0 + y1) / 2 });

    // Measured definitions: shaded +/- 1 sigma bands with a centre line.
    for (weak.measured) |m| {
        if (m.value < s_lo or m.value > s_hi) continue;
        const xa = Sc.x(m.value - m.err);
        const xb = Sc.x(m.value + m.err);
        try w.print("<rect x=\"{d:.1}\" y=\"{d}\" width=\"{d:.2}\" height=\"{d}\" fill=\"{s}\" fill-opacity=\"0.25\"/>\n", .{ xa, y0, @max(1.5, xb - xa), y1 - y0, meas });
        try w.print("<line x1=\"{d:.1}\" y1=\"{d}\" x2=\"{d:.1}\" y2=\"{d}\" stroke=\"{s}\" stroke-width=\"1.5\"/>\n", .{ Sc.x(m.value), y0, Sc.x(m.value), y1, meas });
    }

    // The rule: share = 1/3.
    try w.print("<line x1=\"{d}\" y1=\"{d:.1}\" x2=\"{d}\" y2=\"{d:.1}\" stroke=\"{s}\" stroke-dasharray=\"6 4\" stroke-width=\"1.5\"/>\n", .{ x0, Sc.y(1.0 / 3.0), x1, Sc.y(1.0 / 3.0), rule });

    // The curve.
    try w.print("<path fill=\"none\" stroke=\"{s}\" stroke-width=\"2.5\" d=\"", .{curve});
    var k: usize = 0;
    while (k <= 300) : (k += 1) {
        const sv = s_lo + (s_hi - s_lo) * @as(f64, @floatFromInt(k)) / 300.0;
        try w.print("{s}{d:.1} {d:.1}", .{ if (k == 0) "M" else " L", Sc.x(sv), Sc.y(weak.offAxis(sv)) });
    }
    try w.print("\"/>\n", .{});

    // Solution point.
    const sol = weak.solve(1.0 / 3.0);
    try w.print("<circle cx=\"{d:.1}\" cy=\"{d:.1}\" r=\"6\" fill=\"{s}\" stroke=\"{s}\" stroke-width=\"1.5\"/>\n", .{ Sc.x(sol), Sc.y(1.0 / 3.0), rule, surface });
    try placer.reserveMark(Sc.x(sol), Sc.y(1.0 / 3.0), 7);

    var buf: [80]u8 = undefined;
    const sol_text = std.fmt.bufPrint(&buf, "rule (share = 1/3): {d:.6}", .{sol}) catch "rule";
    try placer.label(w, sol_text, 13, Sc.x(sol), Sc.y(1.0 / 3.0), 7, ink, "bold");
    for (weak.measured) |m| {
        if (m.value < s_lo or m.value > s_hi) continue;
        var mb: [64]u8 = undefined;
        const t = std.fmt.bufPrint(&mb, "{s} {d:.5}", .{ m.name, m.value }) catch m.name;
        try placer.label(w, t, 12, Sc.x(m.value), y0 + 4, 0, ink, "normal");
    }
    try placer.label(w, "share as a function of the angle", 12, Sc.x(0.218), Sc.y(weak.offAxis(0.218)), 3, curve, "normal");

    try w.print("<text x=\"24\" y=\"{d}\" fill=\"{s}\" font-size=\"11\">Green bands: measured values +/- 1 sigma (PDG 2024). Dashed: the 1/3 rule. Z coupling only.</text>\n</svg>\n", .{ height - 14, ink_2 });
    return out.toOwnedSlice();
}

test "weak chart renders" {
    const svg = try render(std.testing.allocator);
    defer std.testing.allocator.free(svg);
    try std.testing.expect(std.mem.endsWith(u8, svg, "</svg>\n"));
}
