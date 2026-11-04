const std = @import("std");

/// Histogram with logarithmically spaced bins, suited to a mass spectrum
/// that spans several decades (J/psi at 3 GeV to Z at 91 GeV).
pub const LogHistogram = struct {
    lo: f64,
    hi: f64,
    counts: []u32,

    pub fn init(gpa: std.mem.Allocator, lo: f64, hi: f64, bins: usize) !LogHistogram {
        const counts = try gpa.alloc(u32, bins);
        @memset(counts, 0);
        return .{ .lo = lo, .hi = hi, .counts = counts };
    }

    pub fn deinit(self: LogHistogram, gpa: std.mem.Allocator) void {
        gpa.free(self.counts);
    }

    pub fn fill(self: *LogHistogram, x: f64) void {
        if (x < self.lo or x >= self.hi) return;
        const f = @log(x / self.lo) / @log(self.hi / self.lo);
        self.counts[@intFromFloat(f * @as(f64, @floatFromInt(self.counts.len)))] += 1;
    }

    /// Lower edge of bin i; edge(counts.len) is the upper limit.
    pub fn edge(self: LogHistogram, i: usize) f64 {
        const f = @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(self.counts.len));
        return self.lo * std.math.pow(f64, self.hi / self.lo, f);
    }

    pub fn max(self: LogHistogram) u32 {
        return std.mem.max(u32, self.counts);
    }
};

/// A known dimuon resonance to look for.
pub const Resonance = struct {
    name: []const u8,
    /// PDG 2024 mass, GeV.
    pdg_mass: f64,
};

pub const known = [_]Resonance{
    // rho and omega overlap at this resolution; the omega mass is quoted.
    .{ .name = "rho/omega", .pdg_mass = 0.78266 },
    .{ .name = "phi", .pdg_mass = 1.019461 },
    .{ .name = "J/psi", .pdg_mass = 3.096900 },
    .{ .name = "psi(2S)", .pdg_mass = 3.686097 },
    .{ .name = "Upsilon(1S)", .pdg_mass = 9.46040 },
    .{ .name = "Upsilon(2S)", .pdg_mass = 10.02340 },
    .{ .name = "Z", .pdg_mass = 91.1880 },
};

pub const Peak = struct {
    mass: f64,
    /// Candidates within the peak window, before background subtraction.
    events: usize,
    /// Peak height over the average of the two sidebands; below ~1.5 the
    /// "peak" is not clearly distinguishable from background.
    significance_ratio: f64,
};

fn countIn(sorted: []const f64, lo: f64, hi: f64) usize {
    const a = std.sort.lowerBound(f64, sorted, lo, orderF64);
    const b = std.sort.lowerBound(f64, sorted, hi, orderF64);
    return b - a;
}

fn orderF64(a: f64, b: f64) std.math.Order {
    return std.math.order(a, b);
}

/// Locate a resonance near `nominal` in a sorted list of masses.
///
/// Mean-shift mode finding: start at the nominal mass and repeatedly move to
/// the mean of all candidates within +/- half_width, which converges on the
/// local density maximum. The peak is then compared against equal-width
/// sidebands on each side to say whether it stands above background.
pub fn findPeak(sorted: []const f64, nominal: f64, relative_half_width: f64) ?Peak {
    const h = nominal * relative_half_width;
    var centre = nominal;
    for (0..50) |_| {
        const a = std.sort.lowerBound(f64, sorted, centre - h, orderF64);
        const b = std.sort.lowerBound(f64, sorted, centre + h, orderF64);
        if (b <= a) return null;
        var sum: f64 = 0;
        for (sorted[a..b]) |m| sum += m;
        const next = sum / @as(f64, @floatFromInt(b - a));
        // Do not wander off to a neighbouring resonance.
        if (@abs(next - nominal) > 2 * h) return null;
        if (@abs(next - centre) < 1e-6 * nominal) {
            centre = next;
            break;
        }
        centre = next;
    }

    const in_peak = countIn(sorted, centre - h, centre + h);
    const left = countIn(sorted, centre - 3 * h, centre - h);
    const right = countIn(sorted, centre + h, centre + 3 * h);
    const sideband = @as(f64, @floatFromInt(left + right)) / 2.0;
    return .{
        .mass = centre,
        .events = in_peak,
        .significance_ratio = @as(f64, @floatFromInt(in_peak)) / @max(1.0, sideband),
    };
}

test "log histogram bins cover the range" {
    var h = try LogHistogram.init(std.testing.allocator, 1, 100, 2);
    defer h.deinit(std.testing.allocator);
    h.fill(5); // first decade
    h.fill(50); // second decade
    h.fill(500); // out of range
    try std.testing.expectEqual(1, h.counts[0]);
    try std.testing.expectEqual(1, h.counts[1]);
    try std.testing.expectApproxEqAbs(10.0, h.edge(1), 1e-9);
}

test "findPeak recovers a peak on flat background" {
    var masses: [3000]f64 = undefined;
    // Flat background from 80 to 100 GeV.
    for (0..2000) |i| masses[i] = 80.0 + 20.0 * @as(f64, @floatFromInt(i)) / 2000.0;
    // Narrow peak around 91.2.
    for (0..1000) |i| masses[2000 + i] = 91.2 + (@as(f64, @floatFromInt(i)) / 1000.0 - 0.5) * 1.0;
    std.mem.sort(f64, &masses, {}, std.sort.asc(f64));

    const peak = findPeak(&masses, 91.0, 0.02).?;
    try std.testing.expectApproxEqAbs(91.2, peak.mass, 0.1);
    try std.testing.expect(peak.significance_ratio > 2.0);
}
