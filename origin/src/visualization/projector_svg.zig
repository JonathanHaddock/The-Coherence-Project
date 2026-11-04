const std = @import("std");
const projector = @import("../analysis/projector.zig");

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

fn legend(w: *std.Io.Writer, x: f64, y: f64, entities: []const Entity) !void {
    for (entities, 0..) |e, i| {
        const ly = y + @as(f64, @floatFromInt(i)) * 22;
        try marker(w, x, ly - 4, 12, e);
        try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"13\">{s}</text>\n", .{ x + 14, ly, ink, e.name });
    }
}

/// The identity-differentiation triangle: each point is v scaled to sum 1,
/// the centre is identity, corners are pure differentiation. Caller frees.
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

    try header(w, width, height, "Identity-differentiation triangle (no mass)");
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
    for ([_]f64{ 0.1, 0.25, 0.5, 0.75 }) |d| {
        const r = @sqrt(2.0 * d / 3.0) / @sqrt(2.0) * side;
        const dashed = d == 0.1 or d == 0.5;
        try w.print("<circle cx=\"{d:.1}\" cy=\"{d:.1}\" r=\"{d:.1}\" fill=\"none\" stroke=\"{s}\" stroke-width=\"1.2\"{s} clip-path=\"url(#tri)\"/>\n", .{
            cx, cy, r, if (dashed) ink_2 else grid, if (dashed) " stroke-dasharray=\"5 4\"" else "",
        });
        try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"11\">D = {d}</text>\n", .{ cx + 4, cy - r + 13, ink_2, d });
    }
    if (true) {
        const r = @sqrt(2.0 * 0.1 / 3.0) / @sqrt(2.0) * side;
        try w.print("<circle cx=\"{d:.1}\" cy=\"{d:.1}\" r=\"{d:.1}\" fill=\"#1baf7a\" fill-opacity=\"0.12\"/>\n", .{ cx, cy, r });
    }
    try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"18\" text-anchor=\"middle\">+</text>\n", .{ cx, cy + 6, ink });
    try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"11\" text-anchor=\"end\">identity</text>\n", .{ cx - 8, cy + 20, ink_2 });

    const corner_labels = [_][]const u8{ "generation 1", "generation 2", "generation 3" };
    const anchors = [_][]const u8{ "end", "start", "middle" };
    const dys = [_]f64{ 22, 22, -12 };
    for (corners, corner_labels, anchors, dys) |c, label, anchor, dy| {
        try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"13\" text-anchor=\"{s}\">{s}</text>\n", .{ c[0], c[1] + dy, ink_2, anchor, label });
    }

    for (points, 0..) |p, i| {
        const sum = p.v[0] + p.v[1] + p.v[2];
        var x: f64 = 0;
        var y: f64 = 0;
        for (0..3) |k| {
            x += p.v[k] / sum * corners[k][0];
            y += p.v[k] / sum * corners[k][1];
        }
        const s = projector.split(p.v);
        try marker(w, x, y, 13, p.entity);
        // Alternate label sides so neighbouring points stay readable.
        const right = i % 2 == 0;
        try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"12\" text-anchor=\"{s}\">{s} {d:.2}</text>\n", .{
            if (right) x + 10 else x - 10, y + 4, ink, if (right) "start" else "end", p.label, s.d,
        });
    }

    try legend(w, 30, 80, entities);
    try w.print("<text x=\"24\" y=\"{d}\" fill=\"{s}\" font-size=\"11\">{s}</text>\n</svg>\n", .{ height - 20, ink_2, footer });
    return out.toOwnedSlice();
}

/// Points on the D axis, one row per entity, with each row's mean marked.
pub fn axis(gpa: std.mem.Allocator, rows: []const []const Point) ![]u8 {
    var out: std.Io.Writer.Allocating = .init(gpa);
    errdefer out.deinit();
    const w = &out.writer;

    const width = 1000.0;
    const row_h = 90.0;
    const top = 90.0;
    const height = top + row_h * @as(f64, @floatFromInt(rows.len)) + 90;
    const x0 = 260.0;
    const x1 = width - 40;
    const sx = struct {
        fn of(d: f64, a: f64, b: f64) f64 {
            return a + (b - a) * d;
        }
    }.of;
    const plot_bottom = top + row_h * @as(f64, @floatFromInt(rows.len));

    try header(w, width, height, "Entities on the identity-differentiation axis (no mass)");
    try w.print("<rect x=\"{d:.1}\" y=\"{d}\" width=\"{d:.1}\" height=\"{d}\" fill=\"#1baf7a\" fill-opacity=\"0.12\"/>\n", .{ x0, top - 20, sx(0.1, x0, x1) - x0, plot_bottom - top + 20 });
    try w.print("<text x=\"{d:.1}\" y=\"{d}\" fill=\"{s}\" font-size=\"11\">identity band</text>\n", .{ x0 + 4, top - 26, ink_2 });
    for ([_]f64{ 0, 0.25, 0.5, 0.75, 1 }) |d| {
        const x = sx(d, x0, x1);
        try w.print("<line x1=\"{d:.1}\" y1=\"{d}\" x2=\"{d:.1}\" y2=\"{d}\" stroke=\"{s}\"{s}/>\n", .{ x, top - 20, x, plot_bottom, if (d == 0.5) ink_2 else grid, if (d == 0.5) " stroke-dasharray=\"5 4\"" else "" });
        try w.print("<text x=\"{d:.1}\" y=\"{d}\" fill=\"{s}\" font-size=\"12\" text-anchor=\"middle\">{d}</text>\n", .{ x, plot_bottom + 20, ink_2, d });
    }
    try w.print("<text x=\"{d:.1}\" y=\"{d}\" fill=\"{s}\" font-size=\"13\" text-anchor=\"middle\">D   (0 = identity, 1 = differentiation)</text>\n", .{ (x0 + x1) / 2, plot_bottom + 44, ink_2 });

    for (rows, 0..) |row, r| {
        const y = top + row_h * (@as(f64, @floatFromInt(r)) + 0.5);
        try w.print("<line x1=\"{d:.1}\" y1=\"{d:.1}\" x2=\"{d:.1}\" y2=\"{d:.1}\" stroke=\"{s}\"/>\n", .{ x0, y, x1, y, grid });
        try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"13\" text-anchor=\"end\">{s}</text>\n", .{ x0 - 14, y + 4, ink, row[0].entity.name });
        var mean: f64 = 0;
        for (row, 0..) |p, i| {
            const d = projector.split(p.v).d;
            mean += d;
            const x = sx(d, x0, x1);
            try marker(w, x, y, 12, p.entity);
            try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"11\" text-anchor=\"middle\">{s}</text>\n", .{ x, if (i % 2 == 0) y - 12 else y + 22, ink, p.label });
        }
        mean /= @floatFromInt(row.len);
        const mx = sx(mean, x0, x1);
        try w.print("<line x1=\"{d:.1}\" y1=\"{d:.1}\" x2=\"{d:.1}\" y2=\"{d:.1}\" stroke=\"{s}\" stroke-width=\"3\"/>\n", .{ mx, y - 26, mx, y + 26, row[0].entity.color });
        try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"12\" font-weight=\"bold\" text-anchor=\"middle\">mean {d:.2}</text>\n", .{ mx, y - 32, ink, mean });
    }
    try w.print("<text x=\"24\" y=\"{d}\" fill=\"{s}\" font-size=\"11\">{s} Bar = row mean.</text>\n</svg>\n", .{ height - 16, ink_2, footer });
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
