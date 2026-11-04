//! Mass differentiation within an entity (Brannen's form of Koide).
//!
//! Three masses of one entity are written as
//!
//!     sqrt(m_k) = mu (1 + A cos(delta + 2 pi k / 3)),  k = 0, 1, 2
//!
//! mu is the identity (shared) scale, A how strongly the copies are
//! differentiated (A^2 = 6 Q - 2, so A = sqrt 2 is Koide's Q = 2/3) and delta
//! the direction of differentiation in the two-dimensional plane. In
//! projector terms: mu is the (1,1,1) component, A and delta the
//! differentiation component's length and angle.

const std = @import("std");

pub const Params = struct { mu: f64, a: f64, delta: f64, q: f64 };

/// Fit (mu, A, delta) to three masses. Order: heaviest first (k = 0), then
/// lightest (k = 1), then middle (k = 2), which puts charged leptons at the
/// conventional delta near 2/9.
pub fn fit(heavy: f64, light: f64, middle: f64) Params {
    const r = [3]f64{ @sqrt(heavy), @sqrt(light), @sqrt(middle) };
    const s = r[0] + r[1] + r[2];
    const mu = s / 3;
    const q = (heavy + light + middle) / (s * s);
    // sum r_k e^{-i 2 pi k / 3} = (3/2) mu A e^{i delta}
    var re: f64 = 0;
    var im: f64 = 0;
    for (r, 0..) |x, k| {
        const ang = -2.0 * std.math.pi * @as(f64, @floatFromInt(k)) / 3.0;
        re += x * @cos(ang);
        im += x * @sin(ang);
    }
    const a = @sqrt(re * re + im * im) / (1.5 * mu);
    return .{ .mu = mu, .a = a, .delta = std.math.atan2(im, re), .q = q };
}

/// Masses from parameters, in the fit's k order.
pub fn masses(p: Params) [3]f64 {
    var out: [3]f64 = undefined;
    for (0..3) |k| {
        const x = p.mu * (1 + p.a * @cos(p.delta + 2.0 * std.math.pi * @as(f64, @floatFromInt(k)) / 3.0));
        out[k] = x * x;
    }
    return out;
}

/// Koide's tau prediction: the m_tau that gives Q = 2/3 exactly.
pub fn koideTau(electron: f64, muon: f64) f64 {
    // With x = sqrt(m_tau), s = sqrt(m_e) + sqrt(m_mu):
    // m_e + m_mu + x^2 = (2/3)(s + x)^2  ->  x^2 - 4 s x + 3(m_e + m_mu) - 2 s^2 = 0
    const s = @sqrt(electron) + @sqrt(muon);
    const c = 3 * (electron + muon) - 2 * s * s;
    const x = 2 * s + @sqrt(4 * s * s - c);
    return x * x;
}

/// Mass ratios fixed by A = sqrt 2 and delta alone (mu cancels).
pub fn ratiosFrom(delta: f64) struct { mu_over_e: f64, tau_over_e: f64 } {
    const m = masses(.{ .mu = 1, .a = std.math.sqrt2, .delta = delta, .q = 2.0 / 3.0 });
    return .{ .mu_over_e = m[2] / m[1], .tau_over_e = m[0] / m[1] };
}

// PDG 2024 charged-lepton masses (MeV).
pub const m_e = 0.51099895000;
pub const m_mu = 105.6583755;
pub const m_mu_err = 0.0000023;

pub const TauMeasurement = struct { name: []const u8, value: f64, err: f64, source: []const u8 };

pub const tau_measurements = [_]TauMeasurement{
    .{ .name = "PDG 2024 average", .value = 1776.93, .err = 0.09, .source = "pdglive S035M" },
    .{ .name = "Belle II (2023)", .value = 1777.09, .err = 0.136, .source = "arXiv:2305.19116, +-0.08 stat +-0.11 syst" },
    .{ .name = "BESIII (2014)", .value = 1776.91, .err = 0.165, .source = "arXiv:1405.1076, +-0.12 stat +0.10/-0.13 syst" },
};

test "fit reproduces the input masses" {
    const p = fit(1776.93, m_e, m_mu);
    const m = masses(p);
    try std.testing.expectApproxEqRel(1776.93, m[0], 1e-9);
    try std.testing.expectApproxEqRel(m_e, m[1], 1e-6);
    try std.testing.expectApproxEqRel(m_mu, m[2], 1e-9);
}

test "Koide tau gives Q = 2/3 and A = sqrt 2" {
    const t = koideTau(m_e, m_mu);
    const p = fit(t, m_e, m_mu);
    try std.testing.expectApproxEqAbs(2.0 / 3.0, p.q, 1e-12);
    try std.testing.expectApproxEqAbs(std.math.sqrt2, p.a, 1e-9);
    try std.testing.expectApproxEqAbs(1776.969, t, 0.001);
}
