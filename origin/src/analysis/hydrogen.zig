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
