//! The weak mixing angle as the quantity the triangle framework could fix.
//!
//! A charged lepton's interaction vector is (EM, weak) = (alpha, alpha_Z
//! (gL^2 + gR^2)), with gL = -1/2 + s, gR = s, s = sin^2(theta_W), and
//! alpha_Z = alpha / (s (1 - s)). The ratio weak/EM depends on s alone:
//!
//!     r(s) = (1/4 - s + 2 s^2) / (s (1 - s))
//!
//! and the off-axis (projected) share is r^2 / (1 + r^2) when EM dominates.

const std = @import("std");

/// Weak-to-EM strength ratio for a charged lepton (Z coupling only).
pub fn ratio(s: f64) f64 {
    return (0.25 - s + 2.0 * s * s) / (s * (1.0 - s));
}

/// Share of the charged-lepton interaction vector off its dominant axis.
pub fn offAxis(s: f64) f64 {
    const r = ratio(s);
    const small = @min(r, 1.0);
    const big = @max(r, 1.0);
    return small * small / (small * small + big * big);
}

/// The angle at which the off-axis share equals `target`, by bisection on
/// [0.15, 0.30] where the share falls monotonically.
pub fn solve(target: f64) f64 {
    var lo: f64 = 0.15;
    var hi: f64 = 0.30;
    for (0..100) |_| {
        const mid = (lo + hi) / 2;
        if (offAxis(mid) > target) lo = mid else hi = mid;
    }
    return (lo + hi) / 2;
}

pub const Measurement = struct {
    name: []const u8,
    value: f64,
    err: f64,
};

/// sin^2(theta_W) in its standard definitions, PDG 2025 update (Dec 2025) of the
/// Review "Electroweak Model and Constraints on New Physics", Table 10.2.
/// (PDG 2024 had MS-bar 0.23129(4), effective 0.23161(4), on-shell 0.22348(10).)
pub const measured = [_]Measurement{
    .{ .name = "MS-bar at m_Z", .value = 0.23122, .err = 0.00006 },
    .{ .name = "MS-bar, ND variant", .value = 0.23140, .err = 0.00006 },
    .{ .name = "effective leptonic", .value = 0.23154, .err = 0.00006 },
    .{ .name = "on-shell (1 - mW^2/mZ^2)", .value = 0.22342, .err = 0.00009 },
};

test "one third share at the MS-bar value" {
    const s = solve(1.0 / 3.0);
    try std.testing.expectApproxEqAbs(0.231246, s, 1e-6);
    try std.testing.expectApproxEqAbs(1.0 / 3.0, offAxis(s), 1e-9);
}

test "share falls as the angle grows" {
    try std.testing.expect(offAxis(0.20) > offAxis(0.23));
    try std.testing.expect(offAxis(0.23) > offAxis(0.26));
}
