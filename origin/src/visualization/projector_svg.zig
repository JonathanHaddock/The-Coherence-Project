const std = @import("std");
const projector = @import("../analysis/projector.zig");
const labels = @import("labels.zig");

// Chart rules (experiments/prime-oscillators/CHART_RULES.md): one colour and
// marker per entity everywhere, fixed axes, conditions in a footer.
const surface = "#fcfcfb";
const ink = "#1f1f1e";
const ink_2 = "#6b6a64";
const grid = "#e6e5e0";

pub const Shape = enum { circle, triangle, square, diamond };

pub const Entity = struct {
    name: []const u8,
    color: []const u8,
    shape: Shape,
};

pub const neutrinos: Entity = .{ .name = "neutrinos (PMNS columns)", .color = "#1baf7a", .shape = .triangle };
pub const charged_leptons: Entity = .{ .name = "charged leptons (PMNS rows)", .color = "#2a78d6", .shape = .circle };
pub const quarks: Entity = .{ .name = "quarks, bound (CKM rows and columns)", .color = "#eb6834", .shape = .square };
pub const user: Entity = .{ .name = "your vector", .color = "#4a3aa7", .shape = .diamond };

pub const Point = struct {
    label: []const u8,
    v: [3]f64,
    entity: Entity,
};

const footer = "Mass-free: PMNS and CKM amplitudes, PDG 2024. D = (Q - 1/3)/(2/3), Q = |v|^2/(sum v)^2. Identity band D &lt;= 0.1.";

fn marker(w: *std.Io.Writer, x: f64, y: f64, size: f64, e: Entity) !void {
    const r = size / 2;
    switch (e.shape) {
        .circle => try w.print("<circle cx=\"{d:.1}\" cy=\"{d:.1}\" r=\"{d:.1}\"", .{ x, y, r }),
        .square => try w.print("<rect x=\"{d:.1}\" y=\"{d:.1}\" width=\"{d:.1}\" height=\"{d:.1}\"", .{ x - r, y - r, size, size }),
        .triangle => try w.print("<polygon points=\"{d:.1},{d:.1} {d:.1},{d:.1} {d:.1},{d:.1}\"", .{ x, y - r * 1.2, x - r * 1.1, y + r * 0.8, x + r * 1.1, y + r * 0.8 }),
        .diamond => try w.print("<polygon points=\"{d:.1},{d:.1} {d:.1},{d:.1} {d:.1},{d:.1} {d:.1},{d:.1}\"", .{ x, y - r * 1.3, x + r * 1.3, y, x, y + r * 1.3, x - r * 1.3, y }),
    }
    try w.print(" fill=\"{s}\" stroke=\"{s}\" stroke-width=\"1.5\"/>\n", .{ e.color, surface });
}

fn header(w: *std.Io.Writer, width: f64, height: f64, title: []const u8) !void {
    try w.print(
        \\<?xml version="1.0" encoding="UTF-8"?>
        \\<svg xmlns="http://www.w3.org/2000/svg" width="{d}" height="{d}" viewBox="0 0 {d} {d}" font-family="Helvetica, Arial, sans-serif">
        \\<rect width="100%" height="100%" fill="{s}"/>
        \\<text x="24" y="38" fill="{s}" font-size="20" font-weight="bold">{s}</text>
        \\
    , .{ width, height, width, height, surface, ink, title });
}

fn legend(w: *std.Io.Writer, placer: *labels.Placer, x: f64, y: f64, entities: []const Entity) !void {
    for (entities, 0..) |e, i| {
        const ly = y + @as(f64, @floatFromInt(i)) * 22;
        try marker(w, x, ly - 4, 12, e);
        try placer.reserveMark(x, ly - 4, 7);
        try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"13\">{s}</text>\n", .{ x + 14, ly, ink, e.name });
        try placer.reserveText(e.name, 13, x + 14, ly, .start);
    }
}

/// Labels that could not be placed in the last render (0 = rule satisfied).
pub var last_clashes: usize = 0;

/// The identity-differentiation triangle: each point is v scaled to sum 1,
/// the centre is identity, corners are pure differentiation. Every label
/// goes through the label placer, so no text overlaps. Caller frees.
pub fn triangle(gpa: std.mem.Allocator, points: []const Point, entities: []const Entity) ![]u8 {
    var out: std.Io.Writer.Allocating = .init(gpa);
    errdefer out.deinit();
    const w = &out.writer;

    const width = 900.0;
    const height = 900.0;
    const side = 640.0;
    const left = (width - side) / 2;
    const base = 720.0;
    const top_y = base - side * @sqrt(3.0) / 2.0;
    const corners = [3][2]f64{ .{ left, base }, .{ left + side, base }, .{ left + side / 2, top_y } };
    const cx = (corners[0][0] + corners[1][0] + corners[2][0]) / 3;
    const cy = (corners[0][1] + corners[1][1] + corners[2][1]) / 3;

    var placer = labels.Placer.init(gpa, .{ .x0 = 8, .y0 = 50, .x1 = width - 8, .y1 = height - 40 });
    defer placer.deinit();

    const title = "Identity-differentiation triangle (no mass)";
    try header(w, width, height, title);
    try placer.reserveText(title, 20, 24, 38, .start);
    try w.print(
        \\<defs><clipPath id="tri"><polygon points="{d:.1},{d:.1} {d:.1},{d:.1} {d:.1},{d:.1}"/></clipPath></defs>
        \\<polygon points="{d:.1},{d:.1} {d:.1},{d:.1} {d:.1},{d:.1}" fill="#f3f2ee" stroke="{s}" stroke-width="1.2"/>
        \\
    , .{
        corners[0][0], corners[0][1], corners[1][0], corners[1][1], corners[2][0], corners[2][1],
        corners[0][0], corners[0][1], corners[1][0], corners[1][1], corners[2][0], corners[2][1], ink_2,
    });

    // Rings of constant D: barycentric distance^2 = 2D/3, which the triangle
    // map scales by side / sqrt 2.
    const ring_d = [_]f64{ 0.1, 0.25, 0.5, 0.75 };
    const band_r = @sqrt(2.0 * 0.1 / 3.0) / @sqrt(2.0) * side;
    try w.print("<circle cx=\"{d:.1}\" cy=\"{d:.1}\" r=\"{d:.1}\" fill=\"#1baf7a\" fill-opacity=\"0.12\"/>\n", .{ cx, cy, band_r });
    for (ring_d) |d| {
        const r = @sqrt(2.0 * d / 3.0) / @sqrt(2.0) * side;
        const dashed = d == 0.1 or d == 0.5;
        try w.print("<circle cx=\"{d:.1}\" cy=\"{d:.1}\" r=\"{d:.1}\" fill=\"none\" stroke=\"{s}\" stroke-width=\"1.2\"{s} clip-path=\"url(#tri)\"/>\n", .{
            cx, cy, r, if (dashed) ink_2 else grid, if (dashed) " stroke-dasharray=\"5 4\"" else "",
        });
    }
    try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"18\" text-anchor=\"middle\">+</text>\n", .{ cx, cy + 6, ink });

    // Pass 1: positions and marks, all reserved before any label is placed.
    var xs: [64]f64 = undefined;
    var ys: [64]f64 = undefined;
    const n = @min(points.len, xs.len);
    for (points[0..n], 0..) |p, i| {
        const sum = p.v[0] + p.v[1] + p.v[2];
        xs[i] = 0;
        ys[i] = 0;
        for (0..3) |k| {
            xs[i] += p.v[k] / sum * corners[k][0];
            ys[i] += p.v[k] / sum * corners[k][1];
        }
        try marker(w, xs[i], ys[i], 13, p.entity);
        try placer.reserveMark(xs[i], ys[i], 8);
    }
    try placer.reserveMark(cx, cy, 6);

    try legend(w, &placer, 30, 80, entities);
    const corner_labels = [_][]const u8{ "generation 1", "generation 2", "generation 3" };
    const anchors = [_]labels.Anchor{ .end, .start, .middle };
    const dys = [_]f64{ 22, 22, -12 };
    for (corners, corner_labels, anchors, dys) |c, text, anchor, dy| {
        try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"13\" text-anchor=\"{s}\">{s}</text>\n", .{ c[0], c[1] + dy, ink_2, anchor.svg(), text });
        try placer.reserveText(text, 13, c[0], c[1] + dy, anchor);
    }

    // Pass 2: data labels first (they matter most), then guide labels.
    for (points[0..n], 0..) |p, i| {
        var buf: [48]u8 = undefined;
        const text = std.fmt.bufPrint(&buf, "{s} {d:.2}", .{ p.label, projector.split(p.v).d }) catch p.label;
        try placer.label(w, text, 12, xs[i], ys[i], 7, ink, "normal");
    }
    try placer.label(w, "identity", 11, cx, cy, 6, ink_2, "normal");
    for (ring_d) |d| {
        const r = @sqrt(2.0 * d / 3.0) / @sqrt(2.0) * side;
        var buf: [16]u8 = undefined;
        const text = std.fmt.bufPrint(&buf, "D = {d}", .{d}) catch "D";
        try placer.label(w, text, 11, cx, cy - r, 0, ink_2, "normal");
    }

    try w.print("<text x=\"24\" y=\"{d}\" fill=\"{s}\" font-size=\"11\">{s}</text>\n</svg>\n", .{ height - 20, ink_2, footer });
    last_clashes = placer.clashes;
    return out.toOwnedSlice();
}

/// Points on the D axis, one row per entity, with each row's mean marked.
pub fn axis(gpa: std.mem.Allocator, rows: []const []const Point) ![]u8 {
    var out: std.Io.Writer.Allocating = .init(gpa);
    errdefer out.deinit();
    const w = &out.writer;

    const width = 1000.0;
    const row_h = 110.0;
    const top = 100.0;
    const height = top + row_h * @as(f64, @floatFromInt(rows.len)) + 90;
    const x0 = 290.0;
    const x1 = width - 60;
    const sx = struct {
        fn of(d: f64, a: f64, b: f64) f64 {
            return a + (b - a) * d;
        }
    }.of;
    const plot_bottom = top + row_h * @as(f64, @floatFromInt(rows.len));

    var placer = labels.Placer.init(gpa, .{ .x0 = 8, .y0 = 50, .x1 = width - 8, .y1 = height - 30 });
    defer placer.deinit();

    const title = "Entities on the identity-differentiation axis (no mass)";
    try header(w, width, height, title);
    try placer.reserveText(title, 20, 24, 38, .start);
    try w.print("<rect x=\"{d:.1}\" y=\"{d}\" width=\"{d:.1}\" height=\"{d}\" fill=\"#1baf7a\" fill-opacity=\"0.12\"/>\n", .{ x0, top - 20, sx(0.1, x0, x1) - x0, plot_bottom - top + 20 });
    for ([_]f64{ 0, 0.25, 0.5, 0.75, 1 }) |d| {
        const x = sx(d, x0, x1);
        try w.print("<line x1=\"{d:.1}\" y1=\"{d}\" x2=\"{d:.1}\" y2=\"{d}\" stroke=\"{s}\"{s}/>\n", .{ x, top - 20, x, plot_bottom, if (d == 0.5) ink_2 else grid, if (d == 0.5) " stroke-dasharray=\"5 4\"" else "" });
        var buf: [8]u8 = undefined;
        const text = std.fmt.bufPrint(&buf, "{d}", .{d}) catch "";
        try w.print("<text x=\"{d:.1}\" y=\"{d}\" fill=\"{s}\" font-size=\"12\" text-anchor=\"middle\">{s}</text>\n", .{ x, plot_bottom + 20, ink_2, text });
        try placer.reserveText(text, 12, x, plot_bottom + 20, .middle);
    }
    const axis_title = "D   (0 = identity, 1 = differentiation)";
    try w.print("<text x=\"{d:.1}\" y=\"{d}\" fill=\"{s}\" font-size=\"13\" text-anchor=\"middle\">{s}</text>\n", .{ (x0 + x1) / 2, plot_bottom + 44, ink_2, axis_title });
    try placer.reserveText(axis_title, 13, (x0 + x1) / 2, plot_bottom + 44, .middle);

    // Pass 1: marks and mean bars for every row.
    var means: [8]f64 = undefined;
    for (rows, 0..) |row, r| {
        const y = top + row_h * (@as(f64, @floatFromInt(r)) + 0.5);
        try w.print("<line x1=\"{d:.1}\" y1=\"{d:.1}\" x2=\"{d:.1}\" y2=\"{d:.1}\" stroke=\"{s}\"/>\n", .{ x0, y, x1, y, grid });
        try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"13\" text-anchor=\"end\">{s}</text>\n", .{ x0 - 14, y + 4, ink, row[0].entity.name });
        try placer.reserveText(row[0].entity.name, 13, x0 - 14, y + 4, .end);
        var mean: f64 = 0;
        for (row) |p| {
            const d = projector.split(p.v).d;
            mean += d;
            try marker(w, sx(d, x0, x1), y, 12, p.entity);
            try placer.reserveMark(sx(d, x0, x1), y, 7);
        }
        mean /= @floatFromInt(row.len);
        means[r] = mean;
        const mx = sx(mean, x0, x1);
        try w.print("<line x1=\"{d:.1}\" y1=\"{d:.1}\" x2=\"{d:.1}\" y2=\"{d:.1}\" stroke=\"{s}\" stroke-width=\"3\"/>\n", .{ mx, y - 22, mx, y + 22, row[0].entity.color });
        try placer.reserve(.{ .x0 = mx - 2, .y0 = y - 22, .x1 = mx + 2, .y1 = y + 22 });
    }
    // Pass 2: labels.
    for (rows, 0..) |row, r| {
        const y = top + row_h * (@as(f64, @floatFromInt(r)) + 0.5);
        var buf: [24]u8 = undefined;
        const text = std.fmt.bufPrint(&buf, "mean {d:.2}", .{means[r]}) catch "mean";
        try placer.label(w, text, 12, sx(means[r], x0, x1), y - 22, 0, ink, "bold");
        for (row) |p| try placer.label(w, p.label, 11, sx(projector.split(p.v).d, x0, x1), y, 6, ink, "normal");
    }
    try placer.label(w, "identity band", 11, sx(0.05, x0, x1), top - 20, 0, ink_2, "normal");

    try w.print("<text x=\"24\" y=\"{d}\" fill=\"{s}\" font-size=\"11\">{s} Bar = row mean.</text>\n</svg>\n", .{ height - 16, ink_2, footer });
    last_clashes = placer.clashes;
    return out.toOwnedSlice();
}

test "triangle and axis render" {
    const pts = [_]Point{.{ .label = "x", .v = .{ 1, 2, 3 }, .entity = user }};
    const t = try triangle(std.testing.allocator, &pts, &.{user});
    defer std.testing.allocator.free(t);
    try std.testing.expect(std.mem.endsWith(u8, t, "</svg>\n"));
    const rows = [_][]const Point{&pts};
    const a = try axis(std.testing.allocator, &rows);
    defer std.testing.allocator.free(a);
    try std.testing.expect(std.mem.indexOf(u8, a, "mean 0.") != null);
}

test "standard charts place every label without overlap" {
    const pmns = projector.pmns();
    var pts: [13]Point = undefined;
    const names = [_][]const u8{ "nu1", "nu2", "nu3", "e", "mu", "tau", "u", "c", "t", "d", "s", "b" };
    for (0..3) |i| {
        pts[i] = .{ .label = names[i], .v = projector.column(pmns, i), .entity = neutrinos };
        pts[3 + i] = .{ .label = names[3 + i], .v = projector.row(pmns, i), .entity = charged_leptons };
        pts[6 + i] = .{ .label = names[6 + i], .v = projector.row(projector.ckm, i), .entity = quarks };
        pts[9 + i] = .{ .label = names[9 + i], .v = projector.column(projector.ckm, i), .entity = quarks };
    }
    // Including a user vector placed right on top of existing points.
    const trial = [_][3]f64{ .{ 1, 1, 1 }, .{ 0.48, 0.58, 0.66 }, .{ 0.0086, 0.041, 0.999 }, .{ 1, 2, 3 } };
    for (trial) |v| {
        pts[12] = .{ .label = "yours", .v = v, .entity = user };
        const t = try triangle(std.testing.allocator, &pts, &.{ neutrinos, charged_leptons, quarks, user });
        std.testing.allocator.free(t);
        try std.testing.expectEqual(0, last_clashes);
        const rows = [_][]const Point{ pts[0..3], pts[3..6], pts[6..12], pts[12..13] };
        const a = try axis(std.testing.allocator, &rows);
        std.testing.allocator.free(a);
        try std.testing.expectEqual(0, last_clashes);
    }
}
