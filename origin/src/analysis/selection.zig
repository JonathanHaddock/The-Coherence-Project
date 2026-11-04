//! Selection and weighting: which forces each entity engages, and how
//! strongly. Port of experiments/lepton-separation/strengths.py.
//!
//! Strength vector per particle v = (EM, weak, strong):
//!   EM     = Q^2 alpha
//!   weak   = alpha_Z (gL^2 + gR^2), gL = T3 - Q s, gR = -Q s
//!            (+ alpha / (2 s) when the W is included)
//!   strong = alpha_s C_F, C_F = 4/3 for quarks
//! Bound quarks average up and down types.

const std = @import("std");

pub const s2w = 0.23129; // MS-bar at m_Z, PDG 2024 Table 10.2

pub const Scale = struct { name: []const u8, alpha: f64, alpha_s: f64 };

pub const scales = [_]Scale{
    .{ .name = "m_Z (91 GeV)", .alpha = 1.0 / 127.95, .alpha_s = 0.1180 },
    .{ .name = "low energy (~2 GeV)", .alpha = 1.0 / 133.5, .alpha_s = 0.30 },
};

pub const Entity = enum { neutrinos, charged_leptons, quarks_bound };

pub const entity_names = [_][]const u8{ "neutrinos", "charged leptons", "quarks (bound)" };

fn fermion(q: f64, t3: f64, quark: bool, sc: Scale, with_w: bool) [3]f64 {
    const alpha_z = sc.alpha / (s2w * (1 - s2w));
    const gl = t3 - q * s2w;
    const gr = -q * s2w;
    const weak = alpha_z * (gl * gl + gr * gr) + (if (with_w) sc.alpha / s2w / 2 else 0);
    return .{ q * q * sc.alpha, weak, if (quark) sc.alpha_s * 4.0 / 3.0 else 0 };
}

pub fn vector(e: Entity, sc: Scale, with_w: bool) [3]f64 {
    return switch (e) {
        .neutrinos => fermion(0, 0.5, false, sc, with_w),
        .charged_leptons => fermion(-1, -0.5, false, sc, with_w),
        .quarks_bound => blk: {
            const u = fermion(2.0 / 3.0, 0.5, true, sc, with_w);
            const d = fermion(-1.0 / 3.0, -0.5, true, sc, with_w);
            break :blk .{ (u[0] + d[0]) / 2, (u[1] + d[1]) / 2, (u[2] + d[2]) / 2 };
        },
    };
}

/// Selectivity S = 1 - H(p)/ln 3: 1 = one force only, 0 = all equally.
pub fn selectivity(v: [3]f64) f64 {
    const sum = v[0] + v[1] + v[2];
    var h: f64 = 0;
    for (v) |x| {
        if (x > 0) h -= (x / sum) * @log(x / sum);
    }
    return 1 - h / @log(3.0);
}

/// Share of the strength vector outside its dominant force.
pub fn offDominant(v: [3]f64) f64 {
    const big = @max(v[0], @max(v[1], v[2]));
    return 1 - big * big / (v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
}

/// Effective number of forces, (sum v)^2 / sum v^2.
pub fn effectiveForces(v: [3]f64) f64 {
    const sum = v[0] + v[1] + v[2];
    return sum * sum / (v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
}

test "neutrinos are perfectly selective, charged leptons least" {
    for (scales) |sc| {
        for ([_]bool{ false, true }) |w| {
            const nu = selectivity(vector(.neutrinos, sc, w));
            const lep = selectivity(vector(.charged_leptons, sc, w));
            const q = selectivity(vector(.quarks_bound, sc, w));
            try std.testing.expectApproxEqAbs(1.0, nu, 1e-12);
            try std.testing.expect(lep < q and q < nu);
        }
    }
}

test "matches the Python experiment at m_Z, Z only" {
    const sc = scales[0];
    try std.testing.expectApproxEqAbs(0.383, selectivity(vector(.charged_leptons, sc, false)), 0.001);
    try std.testing.expectApproxEqAbs(0.775, selectivity(vector(.quarks_bound, sc, false)), 0.001);
}
