const std = @import("std");

/// Koide ratio Q = (m1 + m2 + m3) / (sqrt(m1) + sqrt(m2) + sqrt(m3))^2.
/// Units cancel, so any consistent mass unit works.
pub fn ratio(m1: f64, m2: f64, m3: f64) f64 {
    const s = @sqrt(m1) + @sqrt(m2) + @sqrt(m3);
    return (m1 + m2 + m3) / (s * s);
}

/// Angle in degrees between (sqrt m1, sqrt m2, sqrt m3) and (1,1,1).
/// Q = 2/3 corresponds exactly to 45 degrees (Foot's geometric form).
pub fn angleDegrees(m1: f64, m2: f64, m3: f64) f64 {
    const s = @sqrt(m1) + @sqrt(m2) + @sqrt(m3);
    const norm = @sqrt(m1 + m2 + m3);
    // Clamp: rounding can push the cosine just above 1, which acos turns into NaN.
    const cos_theta = @min(1.0, s / (norm * @sqrt(3.0)));
    return std.math.acos(cos_theta) * 180.0 / std.math.pi;
}

/// Signed Koide ratio: sign[k] = -1 flips the square root of mass k, as in
/// the signed-root extensions of Koide (Rivero; Rodejohann and Zhang).
pub fn signedRatio(m: [3]f64, sign: [3]f64) f64 {
    const s = sign[0] * @sqrt(m[0]) + sign[1] * @sqrt(m[1]) + sign[2] * @sqrt(m[2]);
    return (m[0] + m[1] + m[2]) / (s * s);
}

/// Organizational coordinate from "Lepton coherence": D = (Q - 1/3) / (2/3).
/// D = 0 for equal masses, 1 when one mass dominates. Q = 2/3 gives D = 1/2.
pub fn organization(q: f64) f64 {
    return 1.5 * (q - 1.0 / 3.0);
}

/// Equilibrium function Omega = 4 D (1 - D): 1 at D = 1/2, 0 at either end.
/// Note it is a function of Q alone, so it adds no information beyond Q.
pub fn equilibrium(d: f64) f64 {
    return 4.0 * d * (1.0 - d);
}

/// Neutrino mass-squared splittings, normal ordering (NuFIT 6.0, 2024), eV^2.
pub const nu_dm21_sq = 7.49e-5;
pub const nu_dm31_sq = 2.513e-3;

/// Neutrino masses in eV for a given lightest mass m3, inverted ordering
/// (m3 < m1 < m2). dm32^2 = dm31^2 - dm21^2 in magnitude.
pub fn neutrinoMassesInverted(m3: f64) [3]f64 {
    const dm32 = nu_dm31_sq - nu_dm21_sq;
    return .{ @sqrt(m3 * m3 + dm32 - nu_dm21_sq), @sqrt(m3 * m3 + dm32), m3 };
}

/// Neutrino masses in eV for a given lightest mass m1, normal ordering.
pub fn neutrinoMasses(m1: f64) [3]f64 {
    return .{ m1, @sqrt(m1 * m1 + nu_dm21_sq), @sqrt(m1 * m1 + nu_dm31_sq) };
}

test "ratio bounds" {
    // Equal masses give the minimum Q = 1/3 and angle 0.
    try std.testing.expectApproxEqAbs(1.0 / 3.0, ratio(1, 1, 1), 1e-12);
    try std.testing.expectApproxEqAbs(0.0, angleDegrees(1, 1, 1), 1e-6);
    // One nonzero mass gives the maximum Q = 1.
    try std.testing.expectApproxEqAbs(1.0, ratio(1, 0, 0), 1e-12);
}

test "Q = 2/3 is exactly 45 degrees" {
    // Koide parametrisation: sqrt(m_k) = 1 + sqrt(2) cos(delta + 2 pi k / 3).
    // delta = 0.222 (close to the observed lepton value) keeps every root positive.
    const a = 1.0 + @sqrt(2.0) * @cos(0.222);
    const b = 1.0 + @sqrt(2.0) * @cos(0.222 + 2.0 * std.math.pi / 3.0);
    const c = 1.0 + @sqrt(2.0) * @cos(0.222 + 4.0 * std.math.pi / 3.0);
    try std.testing.expectApproxEqAbs(2.0 / 3.0, ratio(a * a, b * b, c * c), 1e-12);
    try std.testing.expectApproxEqAbs(45.0, angleDegrees(a * a, b * b, c * c), 1e-9);
}

test "normal-ordering neutrinos stay below 2/3" {
    // Q is largest at m1 = 0 and decreases toward 1/3 as m1 grows.
    var previous: f64 = 1.0;
    for ([_]f64{ 0.0, 0.001, 0.01, 0.1, 1.0 }) |m1| {
        const n = neutrinoMasses(m1);
        const q = ratio(n[0], n[1], n[2]);
        try std.testing.expect(q < 2.0 / 3.0);
        try std.testing.expect(q < previous);
        previous = q;
    }
}

test "organization coordinate and equilibrium" {
    try std.testing.expectApproxEqAbs(0.0, organization(1.0 / 3.0), 1e-12);
    try std.testing.expectApproxEqAbs(0.5, organization(2.0 / 3.0), 1e-12);
    try std.testing.expectApproxEqAbs(1.0, organization(1.0), 1e-12);
    try std.testing.expectApproxEqAbs(1.0, equilibrium(0.5), 1e-12);
    try std.testing.expectApproxEqAbs(0.0, equilibrium(1.0), 1e-12);
}

test "signed ratio with all positive signs equals ratio" {
    const m = [3]f64{ 0.511, 105.66, 1776.9 };
    try std.testing.expectApproxEqAbs(ratio(m[0], m[1], m[2]), signedRatio(m, .{ 1, 1, 1 }), 1e-12);
}

test "inverted ordering with massless m3 gives Q = 1/2" {
    // m1 ~ m2 >> m3 = 0: Q -> 2m / (2 sqrt m)^2 = 1/2.
    const n = neutrinoMassesInverted(0.0);
    try std.testing.expectApproxEqAbs(0.5, ratio(n[0], n[1], n[2]), 0.001);
}
