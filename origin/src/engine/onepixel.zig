//! One pixel engine: the inside of a single pixel (Rule Spec v0, sections 2-4, 12).
//! Build order step 1: reproduce beta-decay bookkeeping (charges balance, three
//! flashes per event).
//!
//! From the spec:
//!   - Three cells, bounded by nodes. Cells sit on the lepton points: the three
//!     charged leptons are the points where a cell can operate, and together
//!     form the field where the pattern is displayed (section 3).
//!   - Filled count names the pixel: 0 neutrino, 1 down, 2 up, 3 electron.
//!   - Scaffold (up/down quarks) at the south pole changes the pattern.
//!   - Electron displays it. Neutrino conserves what is not displayed: the
//!     pixel's memory, cycling through three flavors.
//!   - One beta decay = one turn: quark flash (down -> up at the W), electron
//!     flash (display), neutrino flash (conserve). The turn activates five nodes.
//!   - A flash is one cell flipping; the trigger comes from outside (section 12).
//!
//! RULE CHOICES made here (log in the spec before any result is used):
//!   P1 node layout is a setting, not decided: `row` (4 cell-boundary nodes +
//!      the south-pole scaffold node) or `bipyramid` (3 corner nodes + north and
//!      south poles). The spec lists node placement as open (section 9).
//!   P2 which cell the scaffold flips: the empty cell holding the most neutrino
//!      memory, lowest index on ties (same as pixel.zig betaDecay).
//!   P3 neutrino flavor advances one step (e -> mu -> tau -> e) per neutrino flash.
//!   P4 an outside neutrino passing through adds one unit of memory to the
//!      cell it is aimed at; it does not trigger a turn by itself.
//! OPEN (not coded): the reverse stroke (gravity winding up -> down), how mu/tau
//!   "fall back to the electron", and pi at one ninth in the scaffold.

const std = @import("std");
const px = @import("pixel.zig");

pub const Kind = enum { neutrino, down, up, electron };
pub const Layout = enum { row, bipyramid };
pub const Flavor = enum { e, mu, tau };

pub fn kind(pattern: u3) Kind {
    return @enumFromInt(@popCount(pattern));
}

/// Node names for each layout; index 4 is always the south-pole scaffold node.
pub fn nodeNames(l: Layout) [5][]const u8 {
    return switch (l) {
        .row => .{ "b0", "b1", "b2", "b3", "S" },
        .bipyramid => .{ "c01", "c12", "c20", "N", "S" },
    };
}

/// The nodes that bound cell i, plus the scaffold node S.
pub fn cellNodes(l: Layout, i: u2) [2]u3 {
    return switch (l) {
        .row => .{ @intCast(i), @intCast(@as(u3, i) + 1) },
        .bipyramid => .{ @intCast((@as(u3, i) + 2) % 3), @intCast(i) },
    };
}

pub const FlashKind = enum { quark, electron, neutrino };

pub const Flash = struct {
    what: FlashKind,
    charge: i32, // thirds of e carried by this flash (quark flash: change of the pixel)
    nodes: [5]bool,
};

pub const Turn = struct {
    before: u3,
    after: u3,
    cell: u2,
    flashes: [3]Flash,
    flavor: Flavor, // flavor the neutrino flash carries
    /// pixel charge before = pixel after + electron + neutrino (thirds of e)
    pub fn balanced(t: Turn) bool {
        return px.chargeThirds(t.before) == px.chargeThirds(t.after) + t.flashes[1].charge + t.flashes[2].charge;
    }
    pub fn nodesFired(t: Turn) u32 {
        var any: [5]bool = @splat(false);
        for (t.flashes) |f| for (f.nodes, 0..) |on, k| {
            if (on) any[k] = true;
        };
        var c: u32 = 0;
        for (any) |a| c += @intFromBool(a);
        return c;
    }
};

pub const Engine = struct {
    pattern: u3,
    memory: [3]u32 = .{ 0, 0, 0 },
    flavor: Flavor = .e,
    layout: Layout = .row,
    /// charge ledger in thirds of e: pixel + everything emitted
    emitted_thirds: i32 = 0,
    turns: u32 = 0,

    pub fn charge(e: Engine) i32 {
        return px.chargeThirds(e.pattern);
    }
    pub fn total(e: Engine) i32 {
        return e.charge() + e.emitted_thirds;
    }

    /// P4: an outside neutrino passing through cell i.
    pub fn neutrinoPasses(e: *Engine, i: u2) void {
        e.memory[i] += 1;
    }

    /// Outside trigger. Only a down pixel can turn (one cell flips down -> up).
    pub fn trigger(e: *Engine) ?Turn {
        if (kind(e.pattern) != .down) return null;
        var best: ?u2 = null;
        for (0..3) |k| {
            const i: u2 = @intCast(k);
            if (e.pattern & (@as(u3, 1) << i) != 0) continue;
            if (best == null or e.memory[i] > e.memory[best.?]) best = i;
        }
        const c = best.?;
        const before = e.pattern;
        e.pattern |= @as(u3, 1) << c;
        const cn = cellNodes(e.layout, c);
        var quark: [5]bool = @splat(false);
        quark[4] = true; // scaffold at the south pole
        var electron: [5]bool = @splat(false);
        electron[cn[0]] = true;
        electron[cn[1]] = true;
        var neutrino: [5]bool = @splat(false);
        // The remaining nodes: what is not displayed goes to memory.
        for (0..5) |k| neutrino[k] = !quark[k] and !electron[k];
        const fl = e.flavor;
        e.flavor = @enumFromInt((@intFromEnum(e.flavor) + 1) % 3);
        e.memory[c] = 0; // released with the neutrino flash
        const eq = px.chargeThirds(0b111);
        e.emitted_thirds += eq;
        e.turns += 1;
        return .{
            .before = before,
            .after = e.pattern,
            .cell = c,
            .flavor = fl,
            .flashes = .{
                .{ .what = .quark, .charge = px.chargeThirds(e.pattern) - px.chargeThirds(before), .nodes = quark },
                .{ .what = .electron, .charge = eq, .nodes = electron },
                .{ .what = .neutrino, .charge = 0, .nodes = neutrino },
            },
        };
    }
};

pub fn parsePattern(s: []const u8) ?u3 {
    if (s.len != 3) return null;
    var v: u3 = 0;
    for (s, 0..) |ch, i| switch (ch) {
        '1' => v |= @as(u3, 1) << @intCast(i),
        '0' => {},
        else => return null,
    };
    return v;
}

pub fn fmtPattern(p: u3) [3]u8 {
    var out: [3]u8 = undefined;
    for (0..3) |i| out[i] = if (p & (@as(u3, 1) << @intCast(i)) != 0) '1' else '0';
    return out;
}

test "one turn: down -> up, three flashes, charge balances, five nodes" {
    inline for (.{ Layout.row, Layout.bipyramid }) |l| {
        var e: Engine = .{ .pattern = 0b001, .layout = l };
        const start = e.total();
        const t = e.trigger().?;
        try std.testing.expectEqual(Kind.up, kind(t.after));
        try std.testing.expect(t.balanced());
        try std.testing.expectEqual(@as(u32, 5), t.nodesFired());
        try std.testing.expectEqual(start, e.total());
        try std.testing.expectEqual(@as(i32, 3), t.flashes[0].charge); // -1/3 -> +2/3
    }
}

test "only a down pixel turns" {
    for ([_]u3{ 0b000, 0b011, 0b111 }) |p| {
        var e: Engine = .{ .pattern = p };
        try std.testing.expect(e.trigger() == null);
    }
}

test "outside neutrinos choose the flipped cell; flavor cycles" {
    var e: Engine = .{ .pattern = 0b001 };
    e.neutrinoPasses(2);
    const t = e.trigger().?;
    try std.testing.expectEqual(@as(u2, 2), t.cell);
    try std.testing.expectEqual(Flavor.e, t.flavor);
    try std.testing.expectEqual(Flavor.mu, e.flavor);
}

test "pattern text round trip" {
    try std.testing.expectEqual(@as(?u3, 0b101), parsePattern("101"));
    try std.testing.expectEqualStrings("101", &fmtPattern(0b101));
}
