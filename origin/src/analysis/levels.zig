//! Level statistics: tests whether a list of energy levels looks like the
//! Riemann zeta zeros.
//!
//! Pipeline, the same for every source of levels:
//!   1. unfold   - rescale so the mean spacing is 1 (smooth counting function)
//!   2. spacing  - nearest-neighbour gaps against Poisson, GOE, GUE
//!   3. rigidity - number variance Sigma^2(L) against the three ensembles
//!   4. orbits   - Fourier transform of the level density; peaks give the
//!                 periods of the classical periodic orbits. For the zeta
//!                 zeros they should sit at log(p^k).
//!
//! Sources, all deterministic (no random numbers anywhere):
//!   - zeta zeros, computed here with the Riemann-Siegel formula
//!   - integrable control: rectangular box with irrational side ratio

const std = @import("std");
const pi = std.math.pi;

// ---------------------------------------------------------------- zeta zeros

/// Riemann-Siegel theta function (asymptotic series).
pub fn theta(t: f64) f64 {
    return t / 2.0 * @log(t / (2.0 * pi)) - t / 2.0 - pi / 8.0 + 1.0 / (48.0 * t) + 7.0 / (5760.0 * t * t * t);
}

/// Hardy Z function by Riemann-Siegel with the first remainder term.
/// Z is real, and its sign changes are exactly the zeros on the critical line.
pub fn hardyZ(t: f64) f64 {
    const a = @sqrt(t / (2.0 * pi));
    const n_terms: usize = @intFromFloat(@floor(a));
    const th = theta(t);
    var sum: f64 = 0;
    var n: usize = 1;
    while (n <= n_terms) : (n += 1) {
        const nf: f64 = @floatFromInt(n);
        sum += @cos(th - t * @log(nf)) / @sqrt(nf);
    }
    const p = a - @floor(a);
    const c0 = psi(p);
    // C1 = -Psi'''(p) / (96 pi^2), third derivative by central differences.
    const h = 0.01;
    const d3 = (psi(p + 2 * h) - 2 * psi(p + h) + 2 * psi(p - h) - psi(p - 2 * h)) / (2 * h * h * h);
    const c1 = -d3 / (96.0 * pi * pi);
    const sign: f64 = if (n_terms % 2 == 1) 1.0 else -1.0; // (-1)^(N-1)
    return 2.0 * sum + sign * std.math.pow(f64, t / (2.0 * pi), -0.25) * (c0 + c1 / a);
}

fn psi(p: f64) f64 {
    // Removable singularities at p = 1/4, 3/4: nudge off them.
    const pp = if (@abs(@cos(2.0 * pi * p)) < 1e-9) p + 1e-7 else p;
    return @cos(2.0 * pi * (pp * pp - pp - 1.0 / 16.0)) / @cos(2.0 * pi * pp);
}

/// All zeros 0 < t < t_max on the critical line, by scanning Z for sign
/// changes then bisecting. Caller owns the slice.
pub fn zetaZeros(gpa: std.mem.Allocator, t_max: f64) ![]f64 {
    var list: std.ArrayList(f64) = .empty;
    errdefer list.deinit(gpa);
    // Below the first zero (14.13) Riemann-Siegel is inaccurate; start at 10.
    var t: f64 = 10.0;
    // Step well under the mean spacing 2pi/log(t/2pi) so close pairs are caught.
    var z_prev = hardyZ(t);
    while (t < t_max) {
        const step = 0.05 * 2.0 * pi / @log(@max(t, 20.0) / (2.0 * pi));
        const t_next = t + step;
        const z_next = hardyZ(t_next);
        if ((z_prev < 0) != (z_next < 0)) {
            var lo = t;
            var hi = t_next;
            var zl = z_prev;
            for (0..60) |_| {
                const mid = 0.5 * (lo + hi);
                const zm = hardyZ(mid);
                if ((zm < 0) == (zl < 0)) {
                    lo = mid;
                    zl = zm;
                } else hi = mid;
            }
            try list.append(gpa, 0.5 * (lo + hi));
        }
        t = t_next;
        z_prev = z_next;
    }
    return list.toOwnedSlice(gpa);
}

/// Smooth zero count up to height t: (t/2pi)(log(t/2pi) - 1) + 7/8.
pub fn zetaSmoothCount(t: f64) f64 {
    const x = t / (2.0 * pi);
    return x * (@log(x) - 1.0) + 7.0 / 8.0;
}

// ---------------------------------------------------------- integrable box

/// Box side ratio squared. Irrational, so there are no systematic degeneracies.
pub const box_alpha: f64 = (1.0 + 2.2360679774997896964) / 2.0; // golden ratio

/// Lowest `count` levels E = m^2 + alpha n^2 (m, n >= 1): a particle in a
/// rectangle with sides pi and pi/sqrt(alpha). Integrable, so Poisson expected.
pub fn boxLevels(gpa: std.mem.Allocator, count: usize) ![]f64 {
    // Weyl: N(E) ~ pi E / (4 sqrt alpha); pick E_max to overshoot then trim.
    const e_max = 1.2 * @as(f64, @floatFromInt(count)) * 4.0 * @sqrt(box_alpha) / pi + 200.0;
    var list: std.ArrayList(f64) = .empty;
    errdefer list.deinit(gpa);
    var m: usize = 1;
    while (true) : (m += 1) {
        const mf: f64 = @floatFromInt(m);
        if (mf * mf + box_alpha > e_max) break;
        var n: usize = 1;
        while (true) : (n += 1) {
            const nf: f64 = @floatFromInt(n);
            const e = mf * mf + box_alpha * nf * nf;
            if (e > e_max) break;
            try list.append(gpa, e);
        }
    }
    std.mem.sort(f64, list.items, {}, std.sort.asc(f64));
    if (list.items.len > count) list.shrinkRetainingCapacity(count);
    return list.toOwnedSlice(gpa);
}

/// Average count for the box, including the wall correction.
pub fn boxSmoothCount(e: f64) f64 {
    const sa = @sqrt(box_alpha);
    return pi / (4.0 * sa) * e - (1.0 + 1.0 / sa) / 2.0 * @sqrt(e);
}

// ------------------------------------------------------------------ unfolding

/// u_i = N_smooth(level_i). Caller owns the slice.
pub fn unfold(gpa: std.mem.Allocator, levels: []const f64, smooth: *const fn (f64) f64) ![]f64 {
    const u = try gpa.alloc(f64, levels.len);
    for (levels, u) |l, *o| o.* = smooth(l);
    return u;
}

// --------------------------------------------------------- spacing statistics

pub const Ensemble = enum { poisson, goe, gue };

pub fn spacingDensity(e: Ensemble, s: f64) f64 {
    return switch (e) {
        .poisson => @exp(-s),
        .goe => pi * s / 2.0 * @exp(-pi * s * s / 4.0),
        .gue => 32.0 / (pi * pi) * s * s * @exp(-4.0 * s * s / pi),
    };
}

/// Cumulative spacing distribution (Wigner surmise for GOE and GUE).
pub fn spacingCdf(e: Ensemble, s: f64) f64 {
    switch (e) {
        .poisson => return 1.0 - @exp(-s),
        .goe => return 1.0 - @exp(-pi * s * s / 4.0),
        .gue => {
            // Simpson's rule; the density is smooth and tiny past s = 4.
            const n: usize = 400;
            const h = s / @as(f64, @floatFromInt(n));
            var acc = spacingDensity(.gue, 0) + spacingDensity(.gue, s);
            for (1..n) |i| {
                const w: f64 = if (i % 2 == 1) 4.0 else 2.0;
                acc += w * spacingDensity(.gue, h * @as(f64, @floatFromInt(i)));
            }
            return acc * h / 3.0;
        },
    }
}

pub const SpacingResult = struct {
    count: usize,
    mean: f64,
    /// Kolmogorov-Smirnov distance to each ensemble (smaller = closer).
    ks: [3]f64,
    /// Fraction of gaps below 0.25: Poisson 0.221, GOE 0.048, GUE 0.016 (surmise).
    small_frac: f64,
    small_expected: [3]f64,
    /// Histogram on [0, 3) in 30 bins, as a density.
    hist: [30]f64,
};

pub fn spacings(gpa: std.mem.Allocator, unfolded: []const f64) !SpacingResult {
    const n = unfolded.len - 1;
    const s = try gpa.alloc(f64, n);
    defer gpa.free(s);
    var sum: f64 = 0;
    for (0..n) |i| {
        s[i] = unfolded[i + 1] - unfolded[i];
        sum += s[i];
    }
    const mean = sum / @as(f64, @floatFromInt(n));
    std.mem.sort(f64, s, {}, std.sort.asc(f64));

    var r: SpacingResult = .{ .count = n, .mean = mean, .ks = @splat(0), .small_frac = 0, .small_expected = undefined, .hist = @splat(0) };
    const nf: f64 = @floatFromInt(n);
    for (s, 0..) |v, i| {
        const emp_hi = @as(f64, @floatFromInt(i + 1)) / nf;
        const emp_lo = @as(f64, @floatFromInt(i)) / nf;
        inline for (.{ Ensemble.poisson, Ensemble.goe, Ensemble.gue }, 0..) |e, k| {
            const c = spacingCdf(e, v);
            r.ks[k] = @max(r.ks[k], @max(@abs(emp_hi - c), @abs(emp_lo - c)));
        }
        if (v < 0.25) r.small_frac += 1;
        if (v >= 0 and v < 3.0) r.hist[@intFromFloat(v / 0.1)] += 1;
    }
    r.small_frac /= nf;
    for (&r.hist) |*h| h.* /= nf * 0.1;
    inline for (.{ Ensemble.poisson, Ensemble.goe, Ensemble.gue }, 0..) |e, k| r.small_expected[k] = spacingCdf(e, 0.25);
    return r;
}

// ------------------------------------------------------------------- rigidity

pub const rigidity_lengths = [_]f64{ 0.5, 1, 2, 5, 10, 20, 50 };

/// Number variance: variance of the count of unfolded levels in windows of
/// length L, sampled at evenly spaced starts across the sequence.
pub fn numberVariance(unfolded: []const f64, l: f64) f64 {
    const lo = unfolded[0];
    const hi = unfolded[unfolded.len - 1] - l;
    const samples: usize = 20000;
    var sum: f64 = 0;
    var sum2: f64 = 0;
    var a: usize = 0; // first index >= x
    var b: usize = 0; // first index >= x + l
    for (0..samples) |k| {
        const x = lo + (hi - lo) * (@as(f64, @floatFromInt(k)) + 0.5) / @as(f64, @floatFromInt(samples));
        while (a < unfolded.len and unfolded[a] < x) a += 1;
        while (b < unfolded.len and unfolded[b] < x + l) b += 1;
        const c: f64 = @floatFromInt(b - a);
        sum += c;
        sum2 += c * c;
    }
    const m = sum / @as(f64, @floatFromInt(samples));
    return sum2 / @as(f64, @floatFromInt(samples)) - m * m;
}

/// Large-L ensemble predictions.
pub fn numberVarianceTheory(e: Ensemble, l: f64) f64 {
    const euler_gamma = 0.5772156649015329;
    return switch (e) {
        .poisson => l,
        .goe => 2.0 / (pi * pi) * (@log(2.0 * pi * l) + euler_gamma + 1.0 - pi * pi / 8.0),
        .gue => 1.0 / (pi * pi) * (@log(2.0 * pi * l) + euler_gamma + 1.0),
    };
}

// ---------------------------------------------------------------- orbit test

/// The smooth (average) level count for each source.
pub const Smooth = union(enum) {
    zeta,
    box,
    poly: [3]f64,
    pub fn count(self: Smooth, e: f64) f64 {
        return switch (self) {
            .zeta => zetaSmoothCount(e),
            .box => boxSmoothCount(e),
            .poly => |c| c[0] + c[1] * e + c[2] * e * e,
        };
    }
};

/// Loop signal S(x) = sum_n w(E_n) cos(E_n x) minus the same sum spread
/// evenly over the smooth count. What is left is only the wiggles: loops.
/// w is a cos^2 taper so the top of the list doesn't ring.
pub fn orbitSignal(gpa: std.mem.Allocator, lv: []const f64, smooth: Smooth, x_lo: f64, x_hi: f64, out: []f64) !void {
    const e0 = lv[0];
    const e_max = lv[lv.len - 1];
    const taper = struct {
        fn f(e: f64, top: f64) f64 {
            const c = @cos(0.5 * pi * e / top);
            return c * c;
        }
    }.f;
    const w = try gpa.alloc(f64, lv.len);
    defer gpa.free(w);
    for (lv, w) |e, *wi| wi.* = taper(e, e_max);
    // Smooth part on a fine grid: 8 points per wiggle at the largest x.
    const ng: usize = @max(2000, @as(usize, @intFromFloat(8.0 * x_hi * (e_max - e0) / (2.0 * pi))) | 1);
    const ge = try gpa.alloc(f64, ng);
    defer gpa.free(ge);
    const gw = try gpa.alloc(f64, ng);
    defer gpa.free(gw);
    const h = (e_max - e0) / @as(f64, @floatFromInt(ng - 1));
    for (0..ng) |i| {
        const e = e0 + h * @as(f64, @floatFromInt(i));
        const dens = (smooth.count(e + 0.5 * h) - smooth.count(e - 0.5 * h)) / h;
        const simpson: f64 = if (i == 0 or i == ng - 1) 1 else if (i % 2 == 1) 4 else 2;
        ge[i] = e;
        gw[i] = simpson * h / 3.0 * dens * taper(e, e_max);
    }
    const nx = out.len;
    for (out, 0..) |*o, i| {
        const x = x_lo + (x_hi - x_lo) * @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(nx - 1));
        var s: f64 = 0;
        for (lv, w) |e, wi| s += wi * @cos(e * x);
        var sm: f64 = 0;
        for (ge, gw) |e, wi| sm += wi * @cos(e * x);
        o.* = s - sm;
    }
}

/// Von Mangoldt: log p if q = p^k, else 0. Also returns p and k.
pub const PrimePower = struct { p: u32, k: u32 };
pub fn primePower(q: u32) ?PrimePower {
    if (q < 2) return null;
    var p: u32 = 2;
    while (p * p <= q) : (p += 1) {
        if (q % p == 0) {
            var r = q;
            var k: u32 = 0;
            while (r % p == 0) : (r /= p) k += 1;
            return if (r == 1) .{ .p = p, .k = k } else null;
        }
    }
    return .{ .p = q, .k = 1 };
}

// ---------------------------------------------------------------------- tests

test "first zeta zeros match known values" {
    const gpa = std.testing.allocator;
    const z = try zetaZeros(gpa, 50.0);
    defer gpa.free(z);
    const known = [_]f64{ 14.134725, 21.022040, 25.010858, 30.424876, 32.935062, 37.586178, 40.918719, 43.327073, 48.005151, 49.773832 };
    try std.testing.expectEqual(known.len, z.len);
    // Riemann-Siegel is least accurate at the bottom (error ~2.5e-3 at 14.13,
    // falling with height); the spacing there is ~6.
    for (known, z) |k, v| try std.testing.expectApproxEqAbs(k, v, 3e-3);
}

test "zero count to 1000 is 649" {
    const gpa = std.testing.allocator;
    const z = try zetaZeros(gpa, 1000.0);
    defer gpa.free(z);
    try std.testing.expectEqual(@as(usize, 649), z.len);
}

test "prime powers" {
    try std.testing.expectEqual(PrimePower{ .p = 2, .k = 3 }, primePower(8).?);
    try std.testing.expectEqual(PrimePower{ .p = 13, .k = 1 }, primePower(13).?);
    try std.testing.expect(primePower(12) == null);
}

test "gue cdf integrates to 1" {
    try std.testing.expectApproxEqAbs(1.0, spacingCdf(.gue, 6.0), 1e-6);
}

// ------------------------------------------------------- fitted unfolding

/// For spectra with no known smooth count: fit N(E) = c0 + c1 E + c2 E^2 to
/// the staircase (level i sits at count i + 1/2) and use the fit to stretch.
pub fn fitSmooth(lv: []const f64) Smooth {
    var s: [5]f64 = @splat(0); // sums of E^0..E^4
    var t: [3]f64 = @splat(0); // sums of N E^0..E^2
    for (lv, 0..) |e, i| {
        const nn = @as(f64, @floatFromInt(i)) + 0.5;
        var p: f64 = 1;
        for (0..5) |k| {
            s[k] += p;
            if (k < 3) t[k] += nn * p;
            p *= e;
        }
    }
    // Solve the 3x3 normal equations by Cramer's rule.
    const a = [3][3]f64{ .{ s[0], s[1], s[2] }, .{ s[1], s[2], s[3] }, .{ s[2], s[3], s[4] } };
    const det3 = struct {
        fn f(m: [3][3]f64) f64 {
            return m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
        }
    }.f;
    const d = det3(a);
    var c: [3]f64 = undefined;
    for (0..3) |k| {
        var m = a;
        for (0..3) |r| m[r][k] = t[r];
        c[k] = det3(m) / d;
    }
    return .{ .poly = c };
}

/// Share of the loop-length range [lo, hi] lying within `tol` of some log q
/// (q a prime power): how often a feature would land on a prime by chance.
pub fn chanceOnPrime(lo: f64, hi: f64, tol: f64) f64 {
    const steps: usize = 20000;
    var hit: usize = 0;
    for (0..steps) |i| {
        const x = lo + (hi - lo) * (@as(f64, @floatFromInt(i)) + 0.5) / @as(f64, @floatFromInt(steps));
        const q: u32 = @intFromFloat(@round(@exp(x)));
        var near = false;
        var qq = q -| 2;
        while (qq <= q + 2) : (qq += 1) {
            if (primePower(qq) != null and @abs(x - @log(@as(f64, @floatFromInt(qq)))) < tol) near = true;
        }
        if (near) hit += 1;
    }
    return @as(f64, @floatFromInt(hit)) / @as(f64, @floatFromInt(steps));
}

// ---------------------------------------------------------------- strings
// A wave on a string of length 1/2. Its one closed path is there-and-back,
// length 1, repeated at 2, 3, 4, ...
//   tied: both ends held fixed. Each end flips the wave; two flips per trip.
//   half: one end fixed, one free. One flip per trip.

pub fn stringLevels(gpa: std.mem.Allocator, count: usize, half: bool) ![]f64 {
    const out = try gpa.alloc(f64, count);
    for (out, 0..) |*k, i| {
        const n: f64 = @floatFromInt(i);
        k.* = 2.0 * pi * (if (half) n + 0.5 else n + 1.0);
    }
    return out;
}

pub fn stringSmoothCount(half: bool) Smooth {
    // tied: floor(k / 2pi) -> k / 2pi - 1/2 ; half: floor(k / 2pi + 1/2) -> k / 2pi
    return .{ .poly = .{ if (half) 0 else -0.5, 1.0 / (2.0 * pi), 0 } };
}

/// Sign of the loop signal at `x`: the strongest value within `win` of it.
pub fn signalAt(s: []const f64, x_lo: f64, dx: f64, x: f64, win: f64) f64 {
    const c = (x - x_lo) / dx;
    if (c < 0 or c >= @as(f64, @floatFromInt(s.len))) return 0;
    const ci: usize = @intFromFloat(@round(c));
    const w: usize = @intFromFloat(@ceil(win / dx));
    var best: f64 = 0;
    var i = ci -| w;
    while (i <= ci + w and i < s.len) : (i += 1) if (@abs(s[i]) > @abs(best)) {
        best = s[i];
    };
    return best;
}
