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
