const std = @import("std");
const events = @import("../dataset/events.zig");

// Transverse (r-phi) view of a CMS-like detector. Radii in metres.
const tracker_r = 1.1;
const ecal_r = 1.77;
const hcal_r = 2.95;
const solenoid_r = 3.0;
const muon_stations = [_]f64{ 4.0, 4.9, 5.9, 7.0 };
const outer_r = 7.4;

// Magnetic field, tesla (+z out of the page). Inside the solenoid the field
// is uniform; the steel return yoke carries a weaker field the other way,
// which is why CMS muons bend back on themselves. A simplified model.
const b_inner = 3.8;
const b_yoke = -1.8;

const size = 900.0;
const centre = 450.0;
const px_per_m = 400.0 / outer_r;

const muon_colours = [_][]const u8{ "#ff5252", "#42a5f5" };

/// Trace a charged track outward from the beam line and write it as an SVG
/// path. Radius of curvature R = pt / (0.3 |B|), with pt in GeV, R in m.
fn writeTrack(w: *std.Io.Writer, muon: events.Muon, colour: []const u8) !void {
    const step = 0.01; // metres
    var x: f64 = 0;
    var y: f64 = 0;
    var angle = std.math.atan2(muon.p.py, muon.p.px);
    const pt = muon.p.pt();
    const q: f64 = @floatFromInt(muon.charge);

    try w.print("<path fill=\"none\" stroke=\"{s}\" stroke-width=\"2.5\" d=\"M{d:.1} {d:.1}", .{ colour, centre, centre });
    var s: f64 = 0;
    while (s < 3 * outer_r) : (s += step) {
        const r = @sqrt(x * x + y * y);
        if (r >= outer_r) break;
        const field: f64 = if (r < solenoid_r) b_inner else b_yoke;
        // Force q v x B turns a positive track clockwise for B along +z.
        angle -= q * step * 0.3 * field / pt;
        x += step * @cos(angle);
        y += step * @sin(angle);
        if (@mod(s, 0.1) < step) try w.print(" L{d:.1} {d:.1}", .{ centre + x * px_per_m, centre - y * px_per_m });
    }
    try w.print(" L{d:.1} {d:.1}\"/>\n", .{ centre + x * px_per_m, centre - y * px_per_m });
    try w.print("<circle cx=\"{d:.1}\" cy=\"{d:.1}\" r=\"5\" fill=\"{s}\"/>\n", .{ centre + x * px_per_m, centre - y * px_per_m, colour });
}

fn ring(w: *std.Io.Writer, r: f64, stroke: []const u8, fill: []const u8, width: f64) !void {
    try w.print("<circle cx=\"{d}\" cy=\"{d}\" r=\"{d:.1}\" fill=\"{s}\" stroke=\"{s}\" stroke-width=\"{d}\"/>\n", .{ centre, centre, r * px_per_m, fill, stroke, width });
}

/// Render one dimuon event as an SVG event display. Caller frees.
pub fn render(gpa: std.mem.Allocator, title: []const u8, ev: events.DimuonEvent) ![]u8 {
    var out: std.Io.Writer.Allocating = .init(gpa);
    errdefer out.deinit();
    const w = &out.writer;

    try w.print(
        \\<?xml version="1.0" encoding="UTF-8"?>
        \\<svg xmlns="http://www.w3.org/2000/svg" width="{d}" height="{d}" viewBox="0 0 {d} {d}" font-family="monospace">
        \\<rect width="100%" height="100%" fill="#080d18"/>
        \\
    , .{ size, size + 110, size, size + 110 });

    // Detector layers, outside in, so inner layers paint over outer ones.
    for (muon_stations) |r| try ring(w, r, "#4a3b2a", "none", 10);
    try ring(w, solenoid_r, "#5c6b7e", "none", 3);
    try ring(w, hcal_r, "#35465d", "#121a28", 1);
    try ring(w, ecal_r, "#35465d", "#16233a", 1);
    try ring(w, tracker_r, "#35465d", "#0d1524", 1);
    try w.print("<circle cx=\"{d}\" cy=\"{d}\" r=\"4\" fill=\"#ffffff\"/>\n", .{ centre, centre });

    try writeTrack(w, ev.mu1, muon_colours[0]);
    try writeTrack(w, ev.mu2, muon_colours[1]);

    try w.print(
        \\<text x="{d}" y="34" fill="#ffffff" font-size="20" text-anchor="middle">{s}</text>
        \\<text x="{d}" y="58" fill="#8ca5c5" font-size="13" text-anchor="middle">Run {d}  Event {d}  |  dimuon mass {d:.2} GeV  |  B = {d} T</text>
        \\
    , .{ size / 2, title, size / 2, ev.run, ev.event, ev.mass(), b_inner });

    for ([_]events.Muon{ ev.mu1, ev.mu2 }, muon_colours, 0..) |muon, colour, i| {
        const y = size + 30 + @as(f64, @floatFromInt(i)) * 26;
        const sign: []const u8 = if (muon.charge > 0) "+" else "-";
        try w.print("<text x=\"40\" y=\"{d}\" fill=\"{s}\" font-size=\"15\">muon {s}   pt {d:.2} GeV   phi {d:.3} rad   E {d:.2} GeV</text>\n", .{
            y, colour, sign, muon.p.pt(), muon.p.phi(), muon.p.e,
        });
    }
    try w.print(
        \\<text x="40" y="{d}" fill="#8ca5c5" font-size="12">Transverse view. Rings: tracker, ECAL, HCAL, solenoid, muon stations (brown). Field reverses in the return yoke.</text>
        \\</svg>
        \\
    , .{size + 90});

    return out.toOwnedSlice();
}

test "high-momentum track reaches the muon system" {
    const kinematics = @import("../analysis/kinematics.zig");
    const ev: events.DimuonEvent = .{
        .run = 1,
        .event = 1,
        .mu1 = .{ .p = kinematics.FourVector.fromPtEtaPhi(45, 0, 0, kinematics.muon_mass_gev), .charge = 1 },
        .mu2 = .{ .p = kinematics.FourVector.fromPtEtaPhi(45, 0, std.math.pi, kinematics.muon_mass_gev), .charge = -1 },
    };
    const svg = try render(std.testing.allocator, "test", ev);
    defer std.testing.allocator.free(svg);
    try std.testing.expect(std.mem.indexOf(u8, svg, "dimuon mass 90.00 GeV") != null);
}
