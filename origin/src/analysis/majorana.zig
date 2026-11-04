//! Target 2: are neutrinos their own antiparticles (Majorana)?
//!
//! Neutrinoless double-beta decay happens only for Majorana neutrinos, at a
//! rate set by the effective Majorana mass
//!
//!     m_bb = | sum_i U_ei^2 m_i e^{i phi_i} |
//!
//! with |U_e1|^2 = c12^2 c13^2, |U_e2|^2 = s12^2 c13^2, |U_e3|^2 = s13^2 and
//! two unknown Majorana phases. Scanning the phases gives a band:
//! max = sum |U_ei|^2 m_i, min = max(0, 2 max_i(|U_ei|^2 m_i) - sum).
//!
//! Babu and Mohapatra (1989): with right-handed neutrinos, a Majorana mass
//! term forces charge quantization, i.e. the charge shift eps of
//! `charge.zig` must vanish. Targets 1 and 2 are linked.

const std = @import("std");
const koide = @import("koide.zig");

/// PDG 2024 normal-ordering mixing (same as `projector.pmns`).
pub const s12_sq = 0.307;
pub const s13_sq = 0.0219;

pub const Ordering = enum { normal, inverted };

pub fn masses(lightest: f64, ordering: Ordering) [3]f64 {
    return switch (ordering) {
        .normal => koide.neutrinoMasses(lightest),
        .inverted => koide.neutrinoMassesInverted(lightest),
    };
}

/// Weights |U_ei|^2 for mass states 1, 2, 3.
pub fn weights() [3]f64 {
    const c13_sq = 1 - s13_sq;
    return .{ (1 - s12_sq) * c13_sq, s12_sq * c13_sq, s13_sq };
}

pub const Band = struct { min: f64, max: f64 };

/// Range of m_bb (eV) over all Majorana phases.
pub fn band(lightest: f64, ordering: Ordering) Band {
    const m = masses(lightest, ordering);
    const w = weights();
    var terms: [3]f64 = undefined;
    var sum: f64 = 0;
    var biggest: f64 = 0;
    for (0..3) |i| {
        terms[i] = w[i] * m[i];
        sum += terms[i];
        biggest = @max(biggest, terms[i]);
    }
    return .{ .min = @max(0.0, 2 * biggest - sum), .max = sum };
}

pub const Experiment = struct {
    name: []const u8,
    /// Reach in m_bb (eV); the range reflects nuclear-model uncertainty.
    lo: f64,
    hi: f64,
    status: []const u8,
};

pub const experiments = [_]Experiment{
    .{ .name = "KamLAND-Zen 800 (136Xe)", .lo = 0.028, .hi = 0.122, .status = "current limit, T1/2 > 3.8e26 yr" },
    .{ .name = "LEGEND-1000 (76Ge)", .lo = 0.009, .hi = 0.024, .status = "planned" },
    .{ .name = "nEXO (136Xe)", .lo = 0.0047, .hi = 0.0203, .status = "planned" },
};

test "phase band contains both extremes and is ordered" {
    for ([_]f64{ 0, 0.001, 0.01, 0.1 }) |l| {
        for ([_]Ordering{ .normal, .inverted }) |o| {
            const b = band(l, o);
            try std.testing.expect(b.min >= 0);
            try std.testing.expect(b.min <= b.max);
        }
    }
}

test "inverted ordering cannot cancel; normal ordering can" {
    // Inverted: m1 and m2 dominate and cannot cancel fully.
    try std.testing.expect(band(0, .inverted).min > 0.015);
    // Normal: somewhere at a few meV the band reaches zero.
    var reaches_zero = false;
    var l: f64 = 0.0005;
    while (l < 0.01) : (l += 0.0001) {
        if (band(l, .normal).min == 0) reaches_zero = true;
    }
    try std.testing.expect(reaches_zero);
}
