//! Pixel engine: build order steps 1-3 of the engine rules (November 10, 2026).
//!
//! Every rule here is taken from the rules doc. Where the doc left a choice
//! open, the choice is marked RULE CHOICE and must be logged in the doc before
//! any result is used. No coupling knob appears: every number below is a cell
//! count (1, 2, 3) or a neighbor count.
//!
//! RULE CHOICE 1 (display): at a flash a pixel displays cell i filled when its
//!   reinforcement on i beats its conserved share on i; on a tie it keeps the
//!   cell as it was. Deterministic, per the "randomness is not fundamental" claim.
//! RULE CHOICE 2 (trigger): a pixel flashes when its conserved share totals 3,
//!   one full pixel's worth of cells. The trigger therefore comes only from
//!   outside (neighbor flashes), as section 5 requires.
//! RULE CHOICE 3 (no memory): at its own flash a pixel releases its whole
//!   conserved share as the neutrino flash and clears its reinforcement. The
//!   pixel keeps nothing between flashes (section 5: "holds no memory itself").
//! RULE CHOICE 4 (update order): synchronous ticks. Every pixel at threshold
//!   flashes in the same tick; their effects land on neighbors for the next tick.

const std = @import("std");

pub const cells = 3;
pub const threshold: u32 = 3; // RULE CHOICE 2

/// Charge in thirds of e, by filled-cell count (section 2, matter only).
pub fn chargeThirds(pattern: u3) i32 {
    return switch (@popCount(pattern)) {
        0 => 0, // neutrino
        1 => -1, // down
        2 => 2, // up
        3 => -3, // electron
    };
}

pub const Pixel = struct {
    pattern: u3,
    reinforce: [cells]u32 = .{ 0, 0, 0 },
    conserved: [cells]u32 = .{ 0, 0, 0 },
    flashes: u32 = 0,
    last_flash: i64 = -1,

    pub fn memoryTotal(p: Pixel) u32 {
        return p.conserved[0] + p.conserved[1] + p.conserved[2];
    }

    pub fn ready(p: Pixel) bool {
        return p.memoryTotal() >= threshold;
    }

    /// Section 5 flash rule: B compares its cells with A's displayed pattern.
    /// Matching cells are reinforced; non-matching go to B's conserved share.
    pub fn receive(b: *Pixel, shown: u3) void {
        for (0..cells) |i| {
            const bit: u3 = @as(u3, 1) << @intCast(i);
            if ((b.pattern & bit) == (shown & bit)) {
                b.reinforce[i] += 1;
            } else {
                b.conserved[i] += 1;
            }
        }
    }

    /// The pixel's own flash. Returns the neutrino flash: the conserved share released.
    pub fn flash(p: *Pixel, tick: i64) u32 {
        var next = p.pattern;
        for (0..cells) |i| {
            const bit: u3 = @as(u3, 1) << @intCast(i);
            if (p.reinforce[i] > p.conserved[i]) {
                next |= bit;
            } else if (p.reinforce[i] < p.conserved[i]) {
                next &= ~bit;
            }
        }
        p.pattern = next;
        const released = p.memoryTotal();
        p.reinforce = .{ 0, 0, 0 };
        p.conserved = .{ 0, 0, 0 };
        p.flashes += 1;
        p.last_flash = tick;
        return released;
    }
};

// ---------------------------------------------------------------- step 1

pub const BetaEvent = struct {
    before: u3,
    after: u3,
    flipped_cell: u2,
    quark_q: [2]i32, // before, after (thirds)
    electron_q: i32,
    neutrino_q: i32,

    pub fn balanced(e: BetaEvent) bool {
        return e.quark_q[0] == e.quark_q[1] + e.electron_q + e.neutrino_q;
    }
};

/// One beta decay = one cell flip, down (1 filled) to up (2 filled), plus an
/// electron flash and a neutrino flash (sections 4 and 12). The flipped cell is
/// the empty cell holding the largest conserved share, lowest index on ties.
pub fn betaDecay(p: *Pixel) ?BetaEvent {
    if (@popCount(p.pattern) != 1) return null;
    var best: ?u2 = null;
    for (0..cells) |i| {
        const bit: u3 = @as(u3, 1) << @intCast(i);
        if (p.pattern & bit != 0) continue;
        if (best == null or p.conserved[i] > p.conserved[best.?]) best = @intCast(i);
    }
    const before = p.pattern;
    p.pattern |= @as(u3, 1) << best.?;
    return .{
        .before = before,
        .after = p.pattern,
        .flipped_cell = best.?,
        .quark_q = .{ chargeThirds(before), chargeThirds(p.pattern) },
        .electron_q = chargeThirds(0b111),
        .neutrino_q = chargeThirds(0b000),
    };
}

// ---------------------------------------------------------------- step 3

pub const side = 64;
pub const n = side * side;

pub const hist_len = 64;

pub const Grid = struct {
    px: [n]Pixel,
    /// Ticks between successive flashes of the same pixel (last bin = overflow).
    intervals: [hist_len]u64 = @splat(0),

    /// Deterministic seed (xorshift64). Patterns and starting conserved
    /// shares (0..2, below threshold) are drawn from it, so the run is exact
    /// and repeatable. A starting share is needed or nothing ever flashes.
    pub fn init(seed: u64) Grid {
        var g: Grid = .{ .px = undefined };
        var s = seed;
        for (&g.px) |*p| {
            s ^= s << 13;
            s ^= s >> 7;
            s ^= s << 17;
            p.* = .{ .pattern = @truncate(s) };
            for (0..cells) |i| p.conserved[i] = @intCast((s >> @intCast(8 + 2 * i)) % 2);
        }
        return g;
    }

    fn neighbors(i: usize) [4]usize {
        const x = i % side;
        const y = i / side;
        return .{
            y * side + (x + 1) % side,
            y * side + (x + side - 1) % side,
            ((y + 1) % side) * side + x,
            ((y + side - 1) % side) * side + x,
        };
    }

    pub const TickStats = struct {
        flashes: u32,
        neutrino: u32,
        agreement: f64, // mean fraction of matching cells across neighbor bonds
    };

    pub fn tick(g: *Grid, t: i64, kick: ?usize) TickStats {
        var firing: [n]bool = undefined;
        for (g.px, 0..) |p, i| firing[i] = p.ready();
        if (kick) |k| firing[k] = true;

        var shown: [n]u3 = undefined;
        var st: TickStats = .{ .flashes = 0, .neutrino = 0, .agreement = 0 };
        for (&g.px, 0..) |*p, i| {
            if (!firing[i]) continue;
            if (p.last_flash >= 0) {
                const gap: usize = @intCast(t - p.last_flash);
                g.intervals[@min(gap, hist_len - 1)] += 1;
            }
            st.neutrino += p.flash(t);
            shown[i] = p.pattern;
            st.flashes += 1;
        }
        for (0..n) |i| {
            if (!firing[i]) continue;
            for (neighbors(i)) |j| g.px[j].receive(shown[i]);
        }

        var match: u64 = 0;
        for (0..n) |i| {
            for ([_]usize{ neighbors(i)[0], neighbors(i)[2] }) |j| {
                match += cells - @popCount(g.px[i].pattern ^ g.px[j].pattern);
            }
        }
        st.agreement = @as(f64, @floatFromInt(match)) / @as(f64, @floatFromInt(2 * n * cells));
        return st;
    }
};

// ---------------------------------------------------------------- tests

test "beta decay balances charge with three flashes" {
    for ([_]u3{ 0b001, 0b010, 0b100 }) |pat| {
        var p = Pixel{ .pattern = pat };
        const e = betaDecay(&p).?;
        try std.testing.expect(e.balanced());
        try std.testing.expectEqual(@as(u4, 2), @popCount(e.after));
    }
}

test "only a down pixel can beta decay" {
    var up = Pixel{ .pattern = 0b011 };
    try std.testing.expect(betaDecay(&up) == null);
}

test "flash rule splits cells into reinforced and conserved" {
    var b = Pixel{ .pattern = 0b011 };
    b.receive(0b001);
    try std.testing.expectEqual([3]u32{ 1, 0, 1 }, b.reinforce);
    try std.testing.expectEqual([3]u32{ 0, 1, 0 }, b.conserved);
}

test "flash clears the pixel: no memory kept" {
    var b = Pixel{ .pattern = 0b011 };
    b.receive(0b000);
    b.receive(0b000);
    b.receive(0b100);
    try std.testing.expect(b.ready());
    _ = b.flash(0);
    try std.testing.expectEqual(@as(u32, 0), b.memoryTotal());
}
