//! Hydrogen in a strong magnetic field: energy levels for the `levels` checks.
//!
//! What is computed. The electron feels the nucleus and a magnet along z.
//! Stronger magnet = more scrambled (chaotic) electron paths. We hold the
//! *kind* of motion fixed with one number, `eps` (energy measured against
//! field strength): about -0.6 is orderly, about -0.1 is almost fully chaotic.
//! At fixed eps, the list of allowed levels is a list of numbers w (w grows
//! as the field shrinks), and that list is what the four checks look at.
//!
//! How. Two changes of coordinates turn the problem into two coupled
//! springs, (u, v), with z = (u^2 - v^2)/2 and distance from the axis = u v:
//!
//!   [ -1/2 w^-2 (lap_u + lap_v) - eps (u^2 + v^2) + u^2 v^2 (u^2 + v^2) / 8 ] psi = 2 psi
//!
//! Written as   (2 + eps R - S/8) psi = mu K psi,   mu = 1/w^2,
//! with K the kinetic term, R = u^2 + v^2, S = u^4 v^2 + u^2 v^4.
//! One matrix solve gives every level at once. The basis is products of
//! spring states in u and v, kept only up to a total number of nodes, and
//! only states symmetric under flipping z (one parity class), with no spin
//! about the field axis. Mixing classes would hide the avoidance we test for.
//!
//! Every number is deterministic. Convergence is checked by solving at two
//! basis sizes and keeping only levels that agree to 1% of a gap.

const std = @import("std");

const Basis = struct {
    nmax: usize,
    b: f64,
    // 1-D matrices (size nmax + 3) for one spring coordinate xi = u/b, m = 0:
    x: []f64, // xi^2
    x2: []f64, // xi^4
    t: []f64, // -1/2 laplacian
    n1: usize,

    fn at(m: []const f64, n1: usize, i: usize, j: usize) f64 {
        return m[i * n1 + j];
    }
};

fn oneD(gpa: std.mem.Allocator, nmax: usize) !struct { x: []f64, x2: []f64, t: []f64, n1: usize } {
    const n1 = nmax + 3;
    const x = try gpa.alloc(f64, n1 * n1);
    const x2 = try gpa.alloc(f64, n1 * n1);
    const t = try gpa.alloc(f64, n1 * n1);
    @memset(x, 0);
    @memset(x2, 0);
    for (0..n1) |i| {
        const fi: f64 = @floatFromInt(i);
        x[i * n1 + i] = 2 * fi + 1;
        if (i + 1 < n1) {
            x[i * n1 + i + 1] = -(fi + 1);
            x[(i + 1) * n1 + i] = -(fi + 1);
        }
    }
    // xi^4 = (xi^2)^2. Exact for indices <= nmax + 1 because xi^2 is tridiagonal.
    for (0..n1) |i| for (0..n1) |j| {
        var s: f64 = 0;
        for (0..n1) |k| s += x[i * n1 + k] * x[k * n1 + j];
        x2[i * n1 + j] = s;
    };
    // Spring energy (2n + 1) = -1/2 lap + 1/2 xi^2  =>  -1/2 lap = diag(2n+1) - xi^2/2.
    for (0..n1) |i| for (0..n1) |j| {
        const d: f64 = if (i == j) 2 * @as(f64, @floatFromInt(i)) + 1 else 0;
        t[i * n1 + j] = d - 0.5 * x[i * n1 + j];
    };
    return .{ .x = x, .x2 = x2, .t = t, .n1 = n1 };
}

const State = struct { a: u16, c: u16 };

/// Matrix elements <a c | op | d e> on product states (not yet symmetrized).
fn elems(bs: *const Basis, eps: f64, a: usize, c: usize, d: usize, e: usize) [2]f64 {
    const n1 = bs.n1;
    const X = bs.x;
    const X2 = bs.x2;
    const T = bs.t;
    const id_ad: f64 = if (a == d) 1 else 0;
    const id_ce: f64 = if (c == e) 1 else 0;
    const b2 = bs.b * bs.b;
    const k = (Basis.at(T, n1, a, d) * id_ce + id_ad * Basis.at(T, n1, c, e)) / b2;
    const r = b2 * (Basis.at(X, n1, a, d) * id_ce + id_ad * Basis.at(X, n1, c, e));
    const s = b2 * b2 * b2 * (Basis.at(X2, n1, a, d) * Basis.at(X, n1, c, e) + Basis.at(X, n1, a, d) * Basis.at(X2, n1, c, e));
    const m = 2 * id_ad * id_ce + eps * r - s / 8;
    return .{ k, m };
}

/// Levels w at scaled energy `eps`, basis up to `nmax` total nodes, spring
/// length `b`. Sorted ascending. Caller owns the slice.
pub fn levels(gpa: std.mem.Allocator, eps: f64, nmax: usize, b: f64) ![]f64 {
    const d1 = try oneD(gpa, nmax);
    defer gpa.free(d1.x);
    defer gpa.free(d1.x2);
    defer gpa.free(d1.t);
    const bs: Basis = .{ .nmax = nmax, .b = b, .x = d1.x, .x2 = d1.x2, .t = d1.t, .n1 = d1.n1 };

    var states: std.ArrayList(State) = .empty;
    defer states.deinit(gpa);
    for (0..nmax + 1) |a| for (a..nmax + 1) |c| {
        if (a + c <= nmax) try states.append(gpa, .{ .a = @intCast(a), .c = @intCast(c) });
    };
    const n = states.items.len;
    // index lookup on the triangle
    const lookup = try gpa.alloc(u32, (nmax + 1) * (nmax + 1));
    defer gpa.free(lookup);
    @memset(lookup, std.math.maxInt(u32));
    for (states.items, 0..) |st, i| lookup[@as(usize, st.a) * (nmax + 1) + st.c] = @intCast(i);

    const K = try gpa.alloc(f64, n * n);
    defer gpa.free(K);
    const M = try gpa.alloc(f64, n * n);
    defer gpa.free(M);
    @memset(K, 0);
    @memset(M, 0);

    for (states.items, 0..) |st, i| {
        const a: usize = st.a;
        const c: usize = st.c;
        const na: f64 = if (a != c) std.math.sqrt2 else 2.0;
        var d: usize = a -| 2;
        while (d <= a + 2) : (d += 1) {
            var e: usize = c -| 2;
            while (e <= c + 2) : (e += 1) {
                const lo = @min(d, e);
                const hi = @max(d, e);
                if (hi > nmax or lo + hi > nmax) continue;
                const j = lookup[lo * (nmax + 1) + hi];
                if (j < i) continue;
                const nb: f64 = if (lo != hi) std.math.sqrt2 else 2.0;
                var ks: f64 = 0;
                var ms: f64 = 0;
                for ([2][2]usize{ .{ a, c }, .{ c, a } }) |p| for ([2][2]usize{ .{ lo, hi }, .{ hi, lo } }) |q| {
                    const km = elems(&bs, eps, p[0], p[1], q[0], q[1]);
                    ks += km[0];
                    ms += km[1];
                };
                K[i * n + j] = ks / (na * nb);
                K[j * n + i] = K[i * n + j];
                M[i * n + j] = ms / (na * nb);
                M[j * n + i] = M[i * n + j];
            }
        }
    }

    const mu = try generalizedEigenvalues(gpa, M, K, n);
    defer gpa.free(mu);
    var out: std.ArrayList(f64) = .empty;
    errdefer out.deinit(gpa);
    for (mu) |m| if (m > 0) try out.append(gpa, 1.0 / @sqrt(m));
    std.mem.sort(f64, out.items, {}, std.sort.asc(f64));
    return out.toOwnedSlice(gpa);
}

/// Keep only the levels that agree between two basis sizes (to 1% of the
/// local gap), counting up from the bottom until the first disagreement.
pub fn converged(gpa: std.mem.Allocator, small: []const f64, big: []const f64) ![]f64 {
    const k = @min(small.len, big.len);
    var good: usize = 0;
    while (good + 1 < k) : (good += 1) {
        const gap = big[good + 1] - big[good];
        if (@abs(small[good] - big[good]) > 0.01 * gap) break;
    }
    return gpa.dupe(f64, big[0..good]);
}

// ----------------------------------------------------------- linear algebra
// Dense symmetric solvers. M and K are row-major n x n; K must be positive
// definite. Both are overwritten.

fn dot(a: []const f64, b: []const f64) f64 {
    const V = @Vector(8, f64);
    var acc: V = @splat(0);
    var i: usize = 0;
    while (i + 8 <= a.len) : (i += 8) {
        const va: V = a[i..][0..8].*;
        const vb: V = b[i..][0..8].*;
        acc += va * vb;
    }
    var s = @reduce(.Add, acc);
    while (i < a.len) : (i += 1) s += a[i] * b[i];
    return s;
}

fn axpy(y: []f64, alpha: f64, x: []const f64) void {
    for (y, x) |*yi, xi| yi.* += alpha * xi;
}

/// Eigenvalues of M v = mu K v.
pub fn generalizedEigenvalues(gpa: std.mem.Allocator, M: []f64, K: []f64, n: usize) ![]f64 {
    // Cholesky K = L L^T, L stored in the lower triangle of K (row-major).
    for (0..n) |i| {
        const ri = K[i * n ..][0..n];
        for (0..i + 1) |j| {
            const rj = K[j * n ..][0..n];
            const s = ri[j] - dot(ri[0..j], rj[0..j]);
            if (i == j) {
                if (s <= 0) return error.NotPositiveDefinite;
                ri[i] = @sqrt(s);
            } else ri[j] = s / rj[j];
        }
    }
    // C = L^-1 M L^-T: forward-solve rows, transpose, forward-solve again.
    for (0..2) |_| {
        for (0..n) |i| {
            const yi = M[i * n ..][0..n];
            for (0..i) |k| axpy(yi, -K[i * n + k], M[k * n ..][0..n]);
            const inv = 1.0 / K[i * n + i];
            for (yi) |*v| v.* *= inv;
        }
        for (0..n) |i| for (i + 1..n) |j| std.mem.swap(f64, &M[i * n + j], &M[j * n + i]);
    }
    // Symmetrize against rounding.
    for (0..n) |i| for (i + 1..n) |j| {
        const v = 0.5 * (M[i * n + j] + M[j * n + i]);
        M[i * n + j] = v;
        M[j * n + i] = v;
    };
    return symmetricEigenvalues(gpa, M, n);
}

/// Eigenvalues of a dense symmetric matrix (overwritten): reduce to a
/// three-diagonal matrix by reflections, then shifted QL sweeps.
pub fn symmetricEigenvalues(gpa: std.mem.Allocator, A: []f64, n: usize) ![]f64 {
    const d = try gpa.alloc(f64, n);
    errdefer gpa.free(d);
    const e = try gpa.alloc(f64, n);
    defer gpa.free(e);
    const v = try gpa.alloc(f64, n);
    defer gpa.free(v);
    const p = try gpa.alloc(f64, n);
    defer gpa.free(p);
    @memset(e, 0);

    // Reduce the trailing block A[k+1.., k+1..] column by column.
    var k: usize = 0;
    while (k + 2 < n) : (k += 1) {
        const m = n - k - 1; // length of the active vector
        const col = v[0..m];
        for (0..m) |i| col[i] = A[(k + 1 + i) * n + k];
        const alpha_norm = @sqrt(dot(col, col));
        d[k] = A[k * n + k];
        if (alpha_norm == 0) {
            e[k] = 0;
            continue;
        }
        const alpha = if (col[0] > 0) -alpha_norm else alpha_norm;
        e[k] = alpha;
        col[0] -= alpha;
        const vnorm2 = dot(col, col);
        if (vnorm2 == 0) continue;
        // p = A_sub v * 2 / |v|^2 ; q = p - (v.p / |v|^2) v ; A_sub -= v q^T + q v^T
        const pp = p[0..m];
        const scale = 2.0 / vnorm2;
        for (0..m) |i| pp[i] = scale * dot(A[(k + 1 + i) * n + k + 1 ..][0..m], col);
        const kk = 0.5 * scale * dot(col, pp);
        for (0..m) |i| pp[i] -= kk * col[i];
        for (0..m) |i| {
            const row = A[(k + 1 + i) * n + k + 1 ..][0..m];
            axpy(row, -col[i], pp);
            axpy(row, -pp[i], col);
        }
    }
    if (n >= 2) {
        d[n - 2] = A[(n - 2) * n + n - 2];
        e[n - 2] = A[(n - 1) * n + n - 2];
    }
    d[n - 1] = A[(n - 1) * n + n - 1];

    // QL with implicit shifts on (d, e), e[i] couples i and i+1.
    var l: usize = 0;
    while (l < n) : (l += 1) {
        var iter: usize = 0;
        while (true) {
            var m = l;
            while (m + 1 < n) : (m += 1) {
                const dd = @abs(d[m]) + @abs(d[m + 1]);
                if (@abs(e[m]) <= std.math.floatEps(f64) * dd) break;
            }
            if (m == l) break;
            iter += 1;
            if (iter > 60) return error.NoConvergence;
            var g = (d[l + 1] - d[l]) / (2.0 * e[l]);
            var r = std.math.hypot(g, 1.0);
            g = d[m] - d[l] + e[l] / (g + (if (g >= 0) r else -r));
            var s: f64 = 1;
            var c: f64 = 1;
            var pq: f64 = 0;
            var i = m;
            var early = false;
            while (i > l) {
                i -= 1;
                const f = s * e[i];
                const b = c * e[i];
                r = std.math.hypot(f, g);
                e[i + 1] = r;
                if (r == 0) {
                    d[i + 1] -= pq;
                    e[m] = 0;
                    early = true;
                    break;
                }
                s = f / r;
                c = g / r;
                g = d[i + 1] - pq;
                r = (d[i] - g) * s + 2.0 * c * b;
                pq = s * r;
                d[i + 1] = g + pq;
                g = c * r - b;
            }
            if (early) continue;
            d[l] -= pq;
            e[l] = g;
            e[m] = 0;
        }
    }
    std.mem.sort(f64, d, {}, std.sort.asc(f64));
    return d;
}

// ---------------------------------------------------------------------- tests

test "symmetric eigenvalues of a small matrix" {
    const gpa = std.testing.allocator;
    var a = [_]f64{ 4, 1, 2, 0.5, 1, 3, 0, 1, 2, 0, 5, 1.5, 0.5, 1, 1.5, 2 };
    const ev = try symmetricEigenvalues(gpa, &a, 4);
    defer gpa.free(ev);
    // reference from an independent solver
    const want = [_]f64{ 0.77791374, 2.52305533, 3.50636456, 7.19266638 };
    for (want, ev) |w, g| try std.testing.expectApproxEqAbs(w, g, 1e-6);
}

test "lowest magnetized hydrogen levels match a separate prototype" {
    const gpa = std.testing.allocator;
    const w = try levels(gpa, -0.1, 40, 0.45);
    defer gpa.free(w);
    const want = [_]f64{ 0.84705, 1.6472, 2.1161, 2.53284, 2.756, 3.26751, 3.47684, 3.70873 };
    for (want, w[0..want.len]) |x, g| try std.testing.expectApproxEqAbs(x, g, 2e-5);
}

// ------------------------------------------------------------ electron paths
// The classical side: actual paths of the electron at the same setting eps.
// A spectrum loop of length L should match a closed path whose length
// (action) is L. Coordinates as above; the motion obeys
//   1/2 (pu^2 + pv^2) + Vp(u, v) = 2,  Vp = -eps (u^2 + v^2) + u^2 v^2 (u^2 + v^2) / 8.
//
// Search: launch the electron at right angles from a symmetry line
// (across-field line u = v, or the field axis v = 0). If it later crosses a
// symmetry line (u = v, u = 0, v = 0) at right angles, it retraces itself,
// so it is a closed path, length = 2 x (length so far).

pub const Line = enum { across, axis_u0, axis, rest };

pub const Path = struct {
    length: f64,
    from: Line,
    to: Line,
    /// If this path is a shorter path run k times: k and that path's length.
    repeat_of: ?struct { k: u32, base: f64 } = null,
};

fn potential(eps: f64, u: f64, v: f64) f64 {
    return -eps * (u * u + v * v) + u * u * v * v * (u * u + v * v) / 8;
}

fn force(eps: f64, u: f64, v: f64) [2]f64 {
    return .{
        2 * eps * u - (4 * u * u * u * v * v + 2 * u * v * v * v * v) / 8,
        2 * eps * v - (4 * v * v * v * u * u + 2 * v * u * u * u * u) / 8,
    };
}

const Crossing = struct { s: f64, along: f64 };
const max_cross = 16;

const Track = struct {
    n: [3]u8 = .{ 0, 0, 0 },
    c: [3][max_cross]Crossing = undefined,
};

fn integrate(eps: f64, start_u: f64, start_v: f64, start_pu: f64, start_pv: f64, s_max: f64) Track {
    var tr: Track = .{};
    var u = start_u;
    var v = start_v;
    var pu = start_pu;
    var pv = start_pv;
    var s: f64 = 0;
    const h: f64 = 0.001;
    while (s < s_max) {
        const k1p = force(eps, u, v);
        const k2p = force(eps, u + h / 2 * pu, v + h / 2 * pv);
        const k2x = [2]f64{ pu + h / 2 * k1p[0], pv + h / 2 * k1p[1] };
        const k3p = force(eps, u + h / 2 * k2x[0], v + h / 2 * k2x[1]);
        const k3x = [2]f64{ pu + h / 2 * k2p[0], pv + h / 2 * k2p[1] };
        const k4p = force(eps, u + h * k3x[0], v + h * k3x[1]);
        const k4x = [2]f64{ pu + h * k3p[0], pv + h * k3p[1] };
        const nu = u + h / 6 * (pu + 2 * k2x[0] + 2 * k3x[0] + k4x[0]);
        const nv = v + h / 6 * (pv + 2 * k2x[1] + 2 * k3x[1] + k4x[1]);
        const npu = pu + h / 6 * (k1p[0] + 2 * k2p[0] + 2 * k3p[0] + k4p[0]);
        const npv = pv + h / 6 * (k1p[1] + 2 * k2p[1] + 2 * k3p[1] + k4p[1]);
        s += (pu * pu + pv * pv) * h;
        const g0 = [3]f64{ u - v, u, v };
        const g1 = [3]f64{ nu - nv, nu, nv };
        const along = [3]f64{ (npu + npv) / std.math.sqrt2, npv, npu };
        for (0..3) |l| {
            if (g0[l] * g1[l] < 0 and tr.n[l] < max_cross) {
                tr.c[l][tr.n[l]] = .{ .s = s, .along = along[l] };
                tr.n[l] += 1;
            }
        }
        u = nu;
        v = nv;
        pu = npu;
        pv = npv;
    }
    return tr;
}

const Stop = struct { s: f64, side: f64, u: f64, v: f64 };
const StopTrack = struct { n: u8 = 0, c: [max_cross]Stop = undefined };

/// Launch from rest on the edge of the allowed region. Each time the speed
/// nearly drops to zero, record which side of the stopping direction it
/// passed on; a sign change between neighbouring launches is a path that
/// stops dead there and retraces.
fn integrateFromRest(eps: f64, start_u: f64, start_v: f64, s_max: f64) StopTrack {
    var tr: StopTrack = .{};
    var u = start_u;
    var v = start_v;
    var pu: f64 = 0;
    var pv: f64 = 0;
    var s: f64 = 0;
    const h: f64 = 0.001;
    var k_prev: f64 = 0;
    var k_prev2: f64 = 0;
    var steps: usize = 0;
    var mid: [4]f64 = .{ 0, 0, 0, 0 };
    var s_mid: f64 = 0;
    while (s < s_max) : (steps += 1) {
        const k1p = force(eps, u, v);
        const k2p = force(eps, u + h / 2 * pu, v + h / 2 * pv);
        const k2x = [2]f64{ pu + h / 2 * k1p[0], pv + h / 2 * k1p[1] };
        const k3p = force(eps, u + h / 2 * k2x[0], v + h / 2 * k2x[1]);
        const k3x = [2]f64{ pu + h / 2 * k2p[0], pv + h / 2 * k2p[1] };
        const k4p = force(eps, u + h * k3x[0], v + h * k3x[1]);
        const k4x = [2]f64{ pu + h * k3p[0], pv + h * k3p[1] };
        const nu = u + h / 6 * (pu + 2 * k2x[0] + 2 * k3x[0] + k4x[0]);
        const nv = v + h / 6 * (pv + 2 * k2x[1] + 2 * k3x[1] + k4x[1]);
        const npu = pu + h / 6 * (k1p[0] + 2 * k2p[0] + 2 * k3p[0] + k4p[0]);
        const npv = pv + h / 6 * (k1p[1] + 2 * k2p[1] + 2 * k3p[1] + k4p[1]);
        s += (pu * pu + pv * pv) * h;
        u = nu;
        v = nv;
        pu = npu;
        pv = npv;
        const k = 0.5 * (pu * pu + pv * pv);
        if (steps > 50 and k_prev < k_prev2 and k_prev <= k and k_prev < 0.05 and tr.n < max_cross) {
            const f = force(eps, mid[0], mid[1]);
            const fn_ = @sqrt(f[0] * f[0] + f[1] * f[1]);
            tr.c[tr.n] = .{ .s = s_mid, .side = (mid[2] * f[1] - mid[3] * f[0]) / fn_, .u = mid[0], .v = mid[1] };
            tr.n += 1;
        }
        k_prev2 = k_prev;
        k_prev = k;
        mid = .{ u, v, pu, pv };
        s_mid = s;
    }
    return tr;
}

fn bisectRadius(eps: f64, dir_u: f64, dir_v: f64) f64 {
    var lo: f64 = 0;
    var hi: f64 = 50;
    for (0..80) |_| {
        const mid = 0.5 * (lo + hi);
        if (potential(eps, mid * dir_u, mid * dir_v) > 2) hi = mid else lo = mid;
    }
    return lo;
}

/// Closed paths with length up to `max_len`, shortest first, each marked as
/// new or as a repeat of a shorter one. Caller owns the slice.
pub fn paths(gpa: std.mem.Allocator, eps: f64, max_len: f64) ![]Path {
    const n: usize = 3000;
    var found: std.ArrayList(Path) = .empty;
    defer found.deinit(gpa);
    const tracks = try gpa.alloc(Track, n);
    defer gpa.free(tracks);

    for ([2]Line{ .across, .axis }) |start| {
        const edge = switch (start) {
            .across => bisectRadius(eps, std.math.sqrt1_2, std.math.sqrt1_2) * std.math.sqrt1_2,
            else => bisectRadius(eps, 1, 0),
        };
        for (tracks, 0..) |*tr, i| {
            const x = edge * (@as(f64, @floatFromInt(i)) + 0.5) / @as(f64, @floatFromInt(n));
            switch (start) {
                .across => {
                    const p = @sqrt(2 * (2 - potential(eps, x, x)));
                    tr.* = integrate(eps, x, x, p * std.math.sqrt1_2, -p * std.math.sqrt1_2, max_len / 2);
                },
                else => {
                    const p = @sqrt(2 * (2 - potential(eps, x, 0)));
                    tr.* = integrate(eps, x, 0, 0, p, max_len / 2);
                },
            }
        }
        // A closed path sits where the momentum along the crossed line
        // changes sign between neighbouring launches (same crossing number).
        for (0..3) |l| for (0..max_cross) |k| for (0..n - 1) |i| {
            const a = tracks[i];
            const b = tracks[i + 1];
            if (a.n[l] <= k or b.n[l] <= k) continue;
            const ca = a.c[l][k];
            const cb = b.c[l][k];
            if (ca.along * cb.along >= 0 or @abs(ca.s - cb.s) > 0.2) continue;
            const s = ca.s + (cb.s - ca.s) * ca.along / (ca.along - cb.along);
            if (2 * s > max_len) continue;
            try found.append(gpa, .{ .length = 2 * s, .from = start, .to = @enumFromInt(l) });
        };
    }
    // Paths that stop dead and turn around.
    const stops = try gpa.alloc(StopTrack, n);
    defer gpa.free(stops);
    const starts = try gpa.alloc([2]f64, n);
    defer gpa.free(starts);
    for (stops, starts, 0..) |*tr, *st, i| {
        const phi = 0.25 * std.math.pi * (@as(f64, @floatFromInt(i)) + 0.5) / @as(f64, @floatFromInt(n));
        const r = bisectRadius(eps, @cos(phi), @sin(phi));
        st.* = .{ r * @cos(phi), r * @sin(phi) };
        tr.* = integrateFromRest(eps, st[0], st[1], max_len);
    }
    for (0..max_cross) |k| for (0..n - 1) |i| {
        const a = stops[i];
        const b = stops[i + 1];
        if (a.n <= k or b.n <= k) continue;
        const ca = a.c[k];
        const cb = b.c[k];
        if (ca.side * cb.side >= 0 or @abs(ca.s - cb.s) > 0.2) continue;
        const sx = ca.s + (cb.s - ca.s) * ca.side / (ca.side - cb.side);
        // Stopped where it started (up to mirror images of u, v): closed after one leg.
        const same = @abs(@abs(ca.u) - starts[i][0]) < 0.05 and @abs(@abs(ca.v) - starts[i][1]) < 0.05;
        const len = if (same) sx else 2 * sx;
        if (len <= max_len) try found.append(gpa, .{ .length = len, .from = .rest, .to = .rest });
    };
    // The two straight paths: along the field axis, and straight across it.
    {
        const a_axis = bisectRadius(eps, 1, 0);
        const a_diag = bisectRadius(eps, std.math.sqrt1_2, std.math.sqrt1_2);
        for ([2][3]f64{ .{ a_axis, 1, 0 }, .{ a_diag, std.math.sqrt1_2, std.math.sqrt1_2 } }, 0..) |ln, which| {
            const m: usize = 4000;
            var acc: f64 = 0;
            for (0..m) |j| {
                const q = -ln[0] + 2 * ln[0] * (@as(f64, @floatFromInt(j)) + 0.5) / @as(f64, @floatFromInt(m));
                acc += @sqrt(@max(0, 2 * (2 - potential(eps, q * ln[1], q * ln[2])))) * 2 * ln[0] / @as(f64, @floatFromInt(m));
            }
            var k: f64 = 1;
            while (k * acc <= max_len) : (k += 1) {
                if (k == 1) try found.append(gpa, .{ .length = acc, .from = if (which == 0) .axis else .across, .to = if (which == 0) .axis else .across });
            }
        }
    }
    std.mem.sort(Path, found.items, {}, struct {
        fn lt(_: void, a: Path, b: Path) bool {
            return a.length < b.length;
        }
    }.lt);
    // Merge duplicates (the same path found from both ends or both lines).
    var out: std.ArrayList(Path) = .empty;
    errdefer out.deinit(gpa);
    for (found.items) |p| {
        if (out.items.len > 0 and p.length - out.items[out.items.len - 1].length < 0.05) continue;
        try out.append(gpa, p);
    }
    // Mark repeats: length k times a shorter new path (within 0.5%).
    for (out.items, 0..) |*p, i| {
        for (out.items[0..i]) |q| {
            if (q.repeat_of != null) continue;
            const k = @round(p.length / q.length);
            if (k >= 2 and @abs(p.length - k * q.length) < 0.005 * p.length) {
                p.repeat_of = .{ .k = @intFromFloat(k), .base = q.length };
                break;
            }
        }
    }
    return out.toOwnedSlice(gpa);
}

test "electron paths include the shortest one and its repeats" {
    const gpa = std.testing.allocator;
    const ps = try paths(gpa, -0.1, 14);
    defer gpa.free(ps);
    try std.testing.expectApproxEqAbs(4.258, ps[0].length, 0.01);
    var twice = false;
    for (ps) |p| if (p.repeat_of) |r| {
        if (r.k == 2 and @abs(r.base - ps[0].length) < 1e-9) twice = true;
    };
    try std.testing.expect(twice);
}
