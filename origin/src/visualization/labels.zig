//! Chart labelling rule: text never overlaps other text or marks.
//!
//! Every mark and every label reserves a box. A new label tries positions
//! around its anchor (right, left, above, below, then the diagonals),
//! stepping outward until it finds space that is free and inside the plot.
//! A label placed away from its anchor gets a leader line. If no position is
//! free the placement is reported as `clash`, which the tests treat as a
//! failure: a chart that cannot place a label must change, not stack text.

const std = @import("std");

pub const Box = struct {
    x0: f64,
    y0: f64,
    x1: f64,
    y1: f64,

    pub fn overlaps(a: Box, b: Box) bool {
        return a.x0 < b.x1 and b.x0 < a.x1 and a.y0 < b.y1 and b.y0 < a.y1;
    }

    fn inside(a: Box, b: Box) bool {
        return a.x0 >= b.x0 and a.x1 <= b.x1 and a.y0 >= b.y0 and a.y1 <= b.y1;
    }

    fn grow(a: Box, pad: f64) Box {
        return .{ .x0 = a.x0 - pad, .y0 = a.y0 - pad, .x1 = a.x1 + pad, .y1 = a.y1 + pad };
    }
};

pub const Anchor = enum {
    start,
    middle,
    end,

    pub fn svg(self: Anchor) []const u8 {
        return @tagName(self);
    }
};

pub const Placement = struct {
    /// Text position (SVG x, baseline y) and text-anchor.
    x: f64,
    y: f64,
    anchor: Anchor,
    /// Draw a leader line from (lx, ly) to the anchor point.
    leader: bool,
    lx: f64,
    ly: f64,
    clash: bool,
};

/// Conservative width of `text` at `size` px in a sans-serif face.
pub fn textWidth(text: []const u8, size: f64) f64 {
    return @as(f64, @floatFromInt(text.len)) * size * 0.62;
}

/// Box of a text run at baseline (x, y) with the given anchor.
pub fn textBox(text: []const u8, size: f64, x: f64, y: f64, anchor: Anchor) Box {
    const w = textWidth(text, size);
    const x0 = switch (anchor) {
        .start => x,
        .middle => x - w / 2,
        .end => x - w,
    };
    return .{ .x0 = x0, .y0 = y - size * 0.85, .x1 = x0 + w, .y1 = y + size * 0.25 };
}

pub const Placer = struct {
    gpa: std.mem.Allocator,
    boxes: std.ArrayList(Box) = .empty,
    bounds: Box,
    /// Minimum clear space between any two boxes.
    pad: f64 = 2,
    clashes: usize = 0,
    /// Surface colour drawn behind label text so lines pass behind it.
    halo: []const u8 = "#fcfcfb",

    pub fn init(gpa: std.mem.Allocator, bounds: Box) Placer {
        return .{ .gpa = gpa, .bounds = bounds };
    }

    pub fn deinit(self: *Placer) void {
        self.boxes.deinit(self.gpa);
    }

    /// Reserve space for something already drawn (a mark, a fixed label).
    pub fn reserve(self: *Placer, box: Box) !void {
        try self.boxes.append(self.gpa, box);
    }

    pub fn reserveMark(self: *Placer, x: f64, y: f64, radius: f64) !void {
        try self.reserve(.{ .x0 = x - radius, .y0 = y - radius, .x1 = x + radius, .y1 = y + radius });
    }

    pub fn reserveText(self: *Placer, text: []const u8, size: f64, x: f64, y: f64, anchor: Anchor) !void {
        try self.reserve(textBox(text, size, x, y, anchor));
    }

    fn free(self: *Placer, box: Box) bool {
        if (!box.inside(self.bounds)) return false;
        const padded = box.grow(self.pad);
        for (self.boxes.items) |b| {
            if (padded.overlaps(b)) return false;
        }
        return true;
    }

    /// Place a label for a mark at (x, y) of the given radius.
    pub fn place(self: *Placer, text: []const u8, size: f64, x: f64, y: f64, mark_radius: f64) !Placement {
        // Direction order: right, left, up, down, then diagonals.
        const dirs = [_][2]f64{ .{ 1, 0 }, .{ -1, 0 }, .{ 0, -1 }, .{ 0, 1 }, .{ 1, -1 }, .{ -1, -1 }, .{ 1, 1 }, .{ -1, 1 } };
        const gaps = [_]f64{ 4, 12, 22, 36, 54, 78, 110, 150 };
        for (gaps) |gap| {
            const reach = mark_radius + gap;
            for (dirs) |d| {
                const anchor: Anchor = if (d[0] > 0) .start else if (d[0] < 0) .end else .middle;
                const tx = x + d[0] * reach;
                // Vertical: centre the text on the row for side positions,
                // sit above or hang below for vertical ones.
                const ty = if (d[1] < 0) y - reach else if (d[1] > 0) y + reach + size * 0.85 else y + size * 0.32;
                const box = textBox(text, size, tx, ty, anchor);
                if (self.free(box)) {
                    try self.reserve(box);
                    const far = gap > 14;
                    // Leader ends at the nearest point of the label box.
                    const lx = std.math.clamp(x, box.x0, box.x1);
                    const ly = std.math.clamp(y, box.y0, box.y1);
                    return .{ .x = tx, .y = ty, .anchor = anchor, .leader = far, .lx = lx, .ly = ly, .clash = false };
                }
            }
        }
        // No free space anywhere: report it rather than stacking silently.
        self.clashes += 1;
        const box = textBox(text, size, x + mark_radius + 4, y + size * 0.32, .start);
        try self.reserve(box);
        return .{ .x = x + mark_radius + 4, .y = y + size * 0.32, .anchor = .start, .leader = false, .lx = x, .ly = y, .clash = true };
    }

    /// Place and write a label (with a leader line when needed).
    pub fn label(self: *Placer, w: *std.Io.Writer, text: []const u8, size: f64, x: f64, y: f64, mark_radius: f64, color: []const u8, weight: []const u8) !void {
        const p = try self.place(text, size, x, y, mark_radius);
        if (p.leader) {
            try w.print("<line x1=\"{d:.1}\" y1=\"{d:.1}\" x2=\"{d:.1}\" y2=\"{d:.1}\" stroke=\"#9a988f\" stroke-width=\"0.8\"/>\n", .{ x, y, p.lx, p.ly });
        }
        // A halo in the surface colour keeps lines behind the text readable.
        try w.print("<text x=\"{d:.1}\" y=\"{d:.1}\" fill=\"{s}\" font-size=\"{d}\" font-weight=\"{s}\" text-anchor=\"{s}\" stroke=\"{s}\" stroke-width=\"3\" paint-order=\"stroke\" stroke-linejoin=\"round\">{s}</text>\n", .{ p.x, p.y, color, size, weight, p.anchor.svg(), self.halo, text });
    }

    /// True if no two reserved boxes overlap (marks may touch marks).
    pub fn verify(self: *Placer) bool {
        return self.clashes == 0;
    }
};

test "labels for a dense cluster never overlap" {
    var p = Placer.init(std.testing.allocator, .{ .x0 = 0, .y0 = 0, .x1 = 400, .y1 = 400 });
    defer p.deinit();
    // Twelve marks packed within 10 px of each other.
    var marks: [12][2]f64 = undefined;
    for (&marks, 0..) |*m, i| {
        const t: f64 = @floatFromInt(i);
        m.* = .{ 200 + 8 * @cos(t), 200 + 8 * @sin(t) };
        try p.reserveMark(m[0], m[1], 5);
    }
    var placed: [12]Box = undefined;
    for (marks, 0..) |m, i| {
        const r = try p.place("label", 12, m[0], m[1], 5);
        try std.testing.expect(!r.clash);
        placed[i] = textBox("label", 12, r.x, r.y, r.anchor);
    }
    for (0..12) |i| for (i + 1..12) |j| try std.testing.expect(!placed[i].overlaps(placed[j]));
}

test "label avoids a reserved title" {
    var p = Placer.init(std.testing.allocator, .{ .x0 = 0, .y0 = 0, .x1 = 300, .y1 = 100 });
    defer p.deinit();
    try p.reserveText("TITLE TEXT", 14, 100, 50, .start);
    const r = try p.place("x", 12, 95, 46, 3);
    try std.testing.expect(!r.clash);
    try std.testing.expect(!textBox("x", 12, r.x, r.y, r.anchor).overlaps(textBox("TITLE TEXT", 14, 100, 50, .start)));
}
