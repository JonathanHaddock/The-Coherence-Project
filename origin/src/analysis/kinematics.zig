const std = @import("std");

/// Muon rest mass in GeV/c^2 (PDG 2024).
pub const muon_mass_gev = 0.1056583755;

/// Relativistic four-momentum in natural units (GeV, c = 1).
pub const FourVector = struct {
    e: f64,
    px: f64,
    py: f64,
    pz: f64,

    /// Momentum reconstruction from collider coordinates: transverse
    /// momentum, pseudorapidity and azimuth, for a particle of known mass.
    pub fn fromPtEtaPhi(transverse: f64, eta: f64, azimuth: f64, rest_mass: f64) FourVector {
        const px = transverse * @cos(azimuth);
        const py = transverse * @sin(azimuth);
        const pz = transverse * std.math.sinh(eta);
        return .{ .e = @sqrt(px * px + py * py + pz * pz + rest_mass * rest_mass), .px = px, .py = py, .pz = pz };
    }

    pub fn add(a: FourVector, b: FourVector) FourVector {
        return .{ .e = a.e + b.e, .px = a.px + b.px, .py = a.py + b.py, .pz = a.pz + b.pz };
    }

    pub fn pt(v: FourVector) f64 {
        return @sqrt(v.px * v.px + v.py * v.py);
    }

    pub fn phi(v: FourVector) f64 {
        return std.math.atan2(v.py, v.px);
    }

    /// Invariant mass sqrt(E^2 - |p|^2). Clamped at zero, since rounding in
    /// recorded data can make E^2 - |p|^2 slightly negative for light particles.
    pub fn mass(v: FourVector) f64 {
        const m2 = v.e * v.e - (v.px * v.px + v.py * v.py + v.pz * v.pz);
        return @sqrt(@max(0.0, m2));
    }
};

test "particle at rest has its rest mass" {
    const v = FourVector.fromPtEtaPhi(0, 0, 0, muon_mass_gev);
    try std.testing.expectApproxEqAbs(muon_mass_gev, v.mass(), 1e-12);
}

test "back-to-back pair gives the parent mass" {
    // Two massless daughters of 45.6 GeV each, back to back: parent mass 91.2 GeV.
    const a = FourVector.fromPtEtaPhi(45.6, 0, 0, 0);
    const b = FourVector.fromPtEtaPhi(45.6, 0, std.math.pi, 0);
    try std.testing.expectApproxEqAbs(91.2, a.add(b).mass(), 1e-9);
}

test "mass is boost invariant along the beam" {
    // A beam-axis boost shifts rapidity; for massless particles rapidity
    // equals pseudorapidity, so shifting every eta is an exact boost.
    const a = FourVector.fromPtEtaPhi(30, 1.2, 0.4, 0);
    const b = FourVector.fromPtEtaPhi(25, -0.3, 2.9, 0);
    const shifted_a = FourVector.fromPtEtaPhi(30, 1.7, 0.4, 0);
    const shifted_b = FourVector.fromPtEtaPhi(25, 0.2, 2.9, 0);
    try std.testing.expectApproxEqAbs(a.add(b).mass(), shifted_a.add(shifted_b).mass(), 1e-9);
}
