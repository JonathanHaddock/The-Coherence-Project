//! Point reactor kinetics with six delayed-neutron groups and a lumped
//! fuel-temperature feedback loop.
//!
//!   dP/dt  = (rho - beta) / Lambda * P + sum_i lambda_i C_i
//!   dCi/dt = beta_i / Lambda * P - lambda_i C_i
//!   dT/dt  = (dT_nom * P - (T - T_in)) / tau
//!   rho    = rho_ext + alpha * (T - T_0)
//!
//! Delayed-neutron data: Keepin, thermal fission of U-235 (public, standard
//! textbook table). Feedback parameters are illustrative.

const std = @import("std");

pub const lambda = [6]f64{ 0.0124, 0.0305, 0.111, 0.301, 1.14, 3.01 }; // 1/s
pub const beta_i = [6]f64{ 0.000215, 0.001424, 0.001274, 0.002568, 0.000748, 0.000273 };

pub fn betaTotal() f64 {
    var s: f64 = 0;
    for (beta_i) |b| s += b;
    return s;
}

pub const Params = struct {
    gen_time: f64 = 2.0e-5, // prompt neutron generation time Lambda, s
    rho_dollars: f64 = 0.1, // external step reactivity, in dollars
    t_end: f64 = 30.0, // s
    feedback: bool = true,
    alpha: f64 = -3.0e-5, // fuel temperature coefficient, 1/K
    dt_nom: f64 = 300.0, // fuel temperature rise above inlet at P = 1, K
    tau: f64 = 5.0, // fuel thermal time constant, s
    samples: usize = 600,
};

pub const Sample = struct { t: f64, p: f64, rho_dollars: f64, dtemp: f64 };

const N = 8; // P, C1..C6, T (as rise above equilibrium)

fn deriv(p: Params, y: [N]f64, out: *[N]f64) void {
    const beta = betaTotal();
    const rho_ext = p.rho_dollars * beta;
    const rho = rho_ext + (if (p.feedback) p.alpha * y[7] else 0);
    var sum: f64 = 0;
    for (0..6) |i| sum += lambda[i] * y[1 + i];
    out[0] = (rho - beta) / p.gen_time * y[0] + sum;
    for (0..6) |i| out[1 + i] = beta_i[i] / p.gen_time * y[0] - lambda[i] * y[1 + i];
    // y[7] = T - T_0, where T_0 is the equilibrium at P = 1.
    out[7] = (p.dt_nom * (y[0] - 1.0) - y[7]) / p.tau;
}

/// Integrate from steady state at P = 1. Caller frees the samples.
pub fn run(gpa: std.mem.Allocator, p: Params) ![]Sample {
    var y: [N]f64 = undefined;
    y[0] = 1.0;
    for (0..6) |i| y[1 + i] = beta_i[i] / (lambda[i] * p.gen_time);
    y[7] = 0;

    const beta = betaTotal();
    // Step: resolve the prompt time scale where it matters.
    const prompt = @abs(p.rho_dollars * beta - beta) / p.gen_time;
    const dt = @min(1e-3, 0.2 / @max(prompt, 1.0));

    const out = try gpa.alloc(Sample, p.samples + 1);
    const every = p.t_end / @as(f64, @floatFromInt(p.samples));
    var next_s: usize = 0;
    var t: f64 = 0;
    while (next_s <= p.samples) {
        const ts = every * @as(f64, @floatFromInt(next_s));
        while (t + dt <= ts + 1e-12) {
            rk4(p, &y, dt);
            t += dt;
        }
        const rem = ts - t;
        if (rem > 1e-12) {
            rk4(p, &y, rem);
            t = ts;
        }
        const rho = p.rho_dollars + (if (p.feedback) p.alpha * y[7] / beta else 0);
        out[next_s] = .{ .t = t, .p = y[0], .rho_dollars = rho, .dtemp = y[7] };
        next_s += 1;
        if (!std.math.isFinite(y[0]) or y[0] > 1e12) {
            for (next_s..p.samples + 1) |j| out[j] = out[next_s - 1];
            break;
        }
    }
    return out;
}

fn rk4(p: Params, y: *[N]f64, h: f64) void {
    var k1: [N]f64 = undefined;
    var k2: [N]f64 = undefined;
    var k3: [N]f64 = undefined;
    var k4: [N]f64 = undefined;
    var tmp: [N]f64 = undefined;
    deriv(p, y.*, &k1);
    for (0..N) |i| tmp[i] = y[i] + 0.5 * h * k1[i];
    deriv(p, tmp, &k2);
    for (0..N) |i| tmp[i] = y[i] + 0.5 * h * k2[i];
    deriv(p, tmp, &k3);
    for (0..N) |i| tmp[i] = y[i] + h * k3[i];
    deriv(p, tmp, &k4);
    for (0..N) |i| y[i] += h / 6.0 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]);
}

/// Stable period from the inhour equation for a step rho (no feedback):
///   rho = w Lambda + sum beta_i w / (w + lambda_i). Returns period 1/w, s.
pub fn inhourPeriod(rho_dollars: f64, gen_time: f64) f64 {
    const rho = rho_dollars * betaTotal();
    const f = struct {
        fn eval(w: f64, lam: f64) f64 {
            var s = w * lam;
            for (0..6) |i| s += beta_i[i] * w / (w + lambda[i]);
            return s;
        }
    };
    var lo: f64 = 1e-9;
    var hi: f64 = 1e4;
    for (0..200) |_| {
        const mid = @sqrt(lo * hi);
        if (f.eval(mid, gen_time) < rho) lo = mid else hi = mid;
    }
    return 1.0 / @sqrt(lo * hi);
}

/// Equilibrium with feedback: P_eq = 1 - rho_ext / (alpha dT_nom).
pub fn feedbackEquilibrium(p: Params) f64 {
    return 1.0 - p.rho_dollars * betaTotal() / (p.alpha * p.dt_nom);
}

test "steady state stays put at zero reactivity" {
    const s = try run(std.testing.allocator, .{ .rho_dollars = 0, .t_end = 5, .samples = 10 });
    defer std.testing.allocator.free(s);
    try std.testing.expectApproxEqRel(@as(f64, 1), s[10].p, 1e-9);
}

test "asymptotic period matches inhour" {
    const gpa = std.testing.allocator;
    const s = try run(gpa, .{ .rho_dollars = 0.2, .feedback = false, .t_end = 120, .samples = 120 });
    defer gpa.free(s);
    const measured = 10.0 / @log(s[120].p / s[110].p);
    try std.testing.expectApproxEqRel(inhourPeriod(0.2, 2e-5), measured, 1e-2);
}

test "feedback settles at the analytic equilibrium" {
    const gpa = std.testing.allocator;
    const p = Params{ .rho_dollars = 0.3, .t_end = 600, .samples = 60 };
    const s = try run(gpa, p);
    defer gpa.free(s);
    try std.testing.expectApproxEqRel(feedbackEquilibrium(p), s[60].p, 1e-3);
}
