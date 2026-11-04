const std = @import("std");

/// Split of a 3-vector between the identity projector P1 = J/3 (onto the
/// democratic direction (1,1,1)/sqrt 3) and the differentiation projector
/// P2 = I - J/3 (onto the plane orthogonal to it).
///
/// For v = (sqrt m1, sqrt m2, sqrt m3) this reproduces Koide's Q exactly,
/// but nothing here assumes v is a mass: any three-state observable works.
pub const Split = struct {
    /// |P1 v|^2 / |v|^2 = cos^2 theta. 1 = pure identity.
    identity: f64,
    /// |P2 v|^2 / |v|^2 = sin^2 theta. 1 = pure differentiation.
    differentiation: f64,
    /// Angle between v and (1,1,1), degrees.
    angle: f64,
    /// Koide-form ratio |v|^2 / (sum v)^2 = 1 / (3 cos^2 theta).
    q: f64,
    /// Organizational coordinate D = (Q - 1/3) / (2/3).
    d: f64,
    /// Equilibrium Omega = 4 D (1 - D).
    omega: f64,
};

pub fn split(v: [3]f64) Split {
    const sum = v[0] + v[1] + v[2];
    const norm2 = v[0] * v[0] + v[1] * v[1] + v[2] * v[2];
    const identity = sum * sum / (3.0 * norm2);
    const q = norm2 / (sum * sum);
    const d = 1.5 * (q - 1.0 / 3.0);
    return .{
        .identity = identity,
        .differentiation = 1.0 - identity,
        .angle = std.math.acos(@min(1.0, @abs(sum) / @sqrt(3.0 * norm2))) * 180.0 / std.math.pi,
        .q = q,
        .d = d,
        .omega = 4.0 * d * (1.0 - d),
    };
}

pub const Matrix = [3][3]f64;

pub fn row(m: Matrix, i: usize) [3]f64 {
    return m[i];
}

pub fn column(m: Matrix, j: usize) [3]f64 {
    return .{ m[0][j], m[1][j], m[2][j] };
}

/// CKM magnitudes |V_ij|, PDG 2024 global fit (rows u,c,t; columns d,s,b).
pub const ckm: Matrix = .{
    .{ 0.97435, 0.22501, 0.003732 },
    .{ 0.22487, 0.97349, 0.04183 },
    .{ 0.00858, 0.04111, 0.999118 },
};

/// PMNS magnitudes |U_ij| (rows e,mu,tau; columns nu1,nu2,nu3) from the
/// standard parametrisation with PDG 2024 normal-ordering central values.
pub fn pmns() Matrix {
    const s12 = @sqrt(0.307);
    const s23 = @sqrt(0.558);
    const s13 = @sqrt(0.0219);
    const delta = 1.19 * std.math.pi;
    const c12 = @sqrt(1 - s12 * s12);
    const c23 = @sqrt(1 - s23 * s23);
    const c13 = @sqrt(1 - s13 * s13);
    const C = std.math.Complex(f64);
    const e = C.init(@cos(delta), @sin(delta)); // e^{i delta}
    const mag = struct {
        fn of(re: f64, z: C) f64 {
            return C.init(re + z.re, z.im).magnitude();
        }
    }.of;
    return .{
        .{ c12 * c13, s12 * c13, s13 },
        .{ mag(-s12 * c23, e.mul(C.init(-c12 * s23 * s13, 0))), mag(c12 * c23, e.mul(C.init(-s12 * s23 * s13, 0))), s23 * c13 },
        .{ mag(s12 * s23, e.mul(C.init(-c12 * c23 * s13, 0))), mag(-c12 * s23, e.mul(C.init(-s12 * c23 * s13, 0))), c23 * c13 },
    };
}

test "democratic vector is pure identity" {
    const s = split(.{ 1, 1, 1 });
    try std.testing.expectApproxEqAbs(1.0, s.identity, 1e-12);
    try std.testing.expectApproxEqAbs(0.0, s.d, 1e-12);
}

test "single component is pure differentiation" {
    const s = split(.{ 1, 0, 0 });
    try std.testing.expectApproxEqAbs(1.0, s.q, 1e-12);
    try std.testing.expectApproxEqAbs(1.0, s.d, 1e-12);
}

test "sqrt masses reproduce Koide Q" {
    const koide = @import("koide.zig");
    const m = [3]f64{ 0.511, 105.66, 1776.9 };
    const s = split(.{ @sqrt(m[0]), @sqrt(m[1]), @sqrt(m[2]) });
    try std.testing.expectApproxEqAbs(koide.ratio(m[0], m[1], m[2]), s.q, 1e-12);
}

test "mixing matrices are unitary in magnitude" {
    const u = pmns();
    for (0..3) |i| {
        var r: f64 = 0;
        var c: f64 = 0;
        var ck: f64 = 0;
        for (0..3) |j| {
            r += u[i][j] * u[i][j];
            c += u[j][i] * u[j][i];
            ck += ckm[i][j] * ckm[i][j];
        }
        try std.testing.expectApproxEqAbs(1.0, r, 1e-9);
        try std.testing.expectApproxEqAbs(1.0, c, 1e-9);
        try std.testing.expectApproxEqAbs(1.0, ck, 1e-3);
    }
}
