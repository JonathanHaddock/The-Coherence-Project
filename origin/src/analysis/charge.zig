//! Charge dequantization: the neutrino's electric charge as a test target.
//!
//! With right-handed neutrinos, anomaly cancellation no longer fixes the
//! hypercharges completely: electric charges can shift along B - L,
//!
//!     Q(eps) = Q_SM + eps * (B - L)
//!
//! (B - L = 1/3 for quarks, -1 for leptons). The Standard Model with
//! right-handed neutrinos leaves eps free. The selection framework (neutrinos
//! select only the weak force) requires eps = 0 exactly.

const std = @import("std");

pub const Fermion = struct {
    name: []const u8,
    q_sm: f64,
    b_minus_l: f64,
    colours: f64,

    pub fn charge(self: Fermion, eps: f64) f64 {
        return self.q_sm + eps * self.b_minus_l;
    }
};

/// One generation (left- and right-handed parts carry the same charge).
pub const generation = [_]Fermion{
    .{ .name = "neutrino", .q_sm = 0, .b_minus_l = -1, .colours = 1 },
    .{ .name = "charged lepton", .q_sm = -1, .b_minus_l = -1, .colours = 1 },
    .{ .name = "up quark", .q_sm = 2.0 / 3.0, .b_minus_l = 1.0 / 3.0, .colours = 3 },
    .{ .name = "down quark", .q_sm = -1.0 / 3.0, .b_minus_l = 1.0 / 3.0, .colours = 3 },
};

/// Total electric charge of one generation, counting colours.
pub fn generationSum(eps: f64) f64 {
    var sum: f64 = 0;
    for (generation) |f| sum += f.colours * f.charge(eps);
    return sum;
}

pub fn proton(eps: f64) f64 {
    return 2 * generation[2].charge(eps) + generation[3].charge(eps);
}

pub fn neutron(eps: f64) f64 {
    return generation[2].charge(eps) + 2 * generation[3].charge(eps);
}

pub fn hydrogen(eps: f64) f64 {
    return proton(eps) + generation[1].charge(eps);
}

pub fn neutrino(eps: f64) f64 {
    return generation[0].charge(eps);
}

/// A measurement and what it says about eps (in units of e).
pub const Bound = struct {
    name: []const u8,
    /// Measured central value of eps implied by the measurement, and its
    /// 1-sigma error. `constrains` is false when the observable does not
    /// depend on eps at all.
    central: f64,
    err: f64,
    constrains: bool,
    source: []const u8,
};

/// Published limits, converted to eps under the B - L shift:
/// neutron charge = eps, neutrino charge = -eps, hydrogen = 0 for any eps.
pub const bounds = [_]Bound{
    .{ .name = "neutron charge", .central = -0.4e-21, .err = 1.1e-21, .constrains = true, .source = "arXiv:2406.19129 (q_n = (-0.4 +- 1.1)e-21 e)" },
    .{ .name = "neutrino charge, lab neutrality", .central = -0.6e-21, .err = 3.2e-21, .constrains = true, .source = "arXiv:2406.19129 (q_nu = (0.6 +- 3.2)e-21 e)" },
    .{ .name = "neutrino charge, reactor (GEMMA)", .central = 0, .err = 0.75e-12, .constrains = true, .source = "arXiv:1411.2279 (|q_nu| < 1.5e-12 e)" },
    .{ .name = "hydrogen / matter neutrality", .central = 0, .err = 2.6e-21, .constrains = false, .source = "arXiv:2406.19129 (q_p + q_e = (0.2 +- 2.6)e-21 e)" },
};

test "every generation stays neutral for any eps" {
    for ([_]f64{ 0, 1e-3, -0.2, 0.5 }) |eps| {
        try std.testing.expectApproxEqAbs(0.0, generationSum(eps), 1e-12);
    }
}

test "hydrogen is neutral for any eps; neutron and neutrino carry eps" {
    for ([_]f64{ 0, 1e-3, -0.2, 0.5 }) |eps| {
        try std.testing.expectApproxEqAbs(0.0, hydrogen(eps), 1e-12);
        try std.testing.expectApproxEqAbs(eps, neutron(eps), 1e-12);
        try std.testing.expectApproxEqAbs(-eps, neutrino(eps), 1e-12);
    }
}

test "beta decay conserves charge for any eps" {
    // n -> p + e + anti-neutrino
    for ([_]f64{ 0, 1e-3, -0.2 }) |eps| {
        const after = proton(eps) + generation[1].charge(eps) - neutrino(eps);
        try std.testing.expectApproxEqAbs(neutron(eps), after, 1e-12);
    }
}
