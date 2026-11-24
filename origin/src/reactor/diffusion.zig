//! One-dimensional two-group neutron diffusion, finite volume.
//!
//! Solves the k-eigenvalue problem
//!   -div D1 grad phi1 + (Sa1 + S12) phi1 = (nuSf1 phi1 + nuSf2 phi2) / k
//!   -div D2 grad phi2 + Sa2 phi2         = S12 phi1
//! on a slab, an infinite cylinder or a sphere built from concentric regions.
//! Centre: symmetry (zero current). Outer edge: vacuum, flux extrapolated to
//! zero 2.13 D beyond the surface. Power iteration on the fission source,
//! each group solved directly with the Thomas algorithm.

const std = @import("std");
const materials = @import("materials.zig");
const Material = materials.Material;

pub const Geometry = enum {
    slab,
    cylinder,
    sphere,

    pub fn parse(s: []const u8) ?Geometry {
        if (std.ascii.eqlIgnoreCase(s, "slab")) return .slab;
        if (std.ascii.eqlIgnoreCase(s, "cyl") or std.ascii.eqlIgnoreCase(s, "cylinder")) return .cylinder;
        if (std.ascii.eqlIgnoreCase(s, "sphere")) return .sphere;
        return null;
    }

    fn area(g: Geometry, r: f64) f64 {
        return switch (g) {
            .slab => 1.0,
            .cylinder => r,
            .sphere => r * r,
        };
    }

    fn volume(g: Geometry, a: f64, b: f64) f64 {
        return switch (g) {
            .slab => b - a,
            .cylinder => (b * b - a * a) / 2.0,
            .sphere => (b * b * b - a * a * a) / 3.0,
        };
    }
};

pub const Region = struct {
    mat: Material,
    thickness: f64, // cm (for the slab: half-thickness of the first region)
};

pub const Result = struct {
    k: f64,
    iterations: u32,
    r: []f64, // cell centres, cm
    phi1: []f64,
    phi2: []f64,
    power: []f64, // fission rate density, mean over fuel = 1
    peaking: f64, // max / mean power over fuel cells
    fuel_edge: f64,

    pub fn deinit(self: *Result, gpa: std.mem.Allocator) void {
        gpa.free(self.r);
        gpa.free(self.phi1);
        gpa.free(self.phi2);
        gpa.free(self.power);
    }
};

pub const Options = struct {
    cell_size: f64 = 0.5, // cm, target
    tol: f64 = 1e-8,
    max_iter: u32 = 2000,
};

pub fn solve(gpa: std.mem.Allocator, geom: Geometry, regions: []const Region, opt: Options) !Result {
    // Build mesh.
    var n: usize = 0;
    for (regions) |reg| n += @max(4, @as(usize, @intFromFloat(@ceil(reg.thickness / opt.cell_size))));

    const edge = try gpa.alloc(f64, n + 1);
    defer gpa.free(edge);
    const mat = try gpa.alloc(Material, n);
    defer gpa.free(mat);
    var i: usize = 0;
    var pos: f64 = 0;
    edge[0] = 0;
    var fuel_edge: f64 = 0;
    for (regions) |reg| {
        const m = @max(4, @as(usize, @intFromFloat(@ceil(reg.thickness / opt.cell_size))));
        const h = reg.thickness / @as(f64, @floatFromInt(m));
        for (0..m) |_| {
            mat[i] = reg.mat;
            pos += h;
            edge[i + 1] = pos;
            i += 1;
        }
        if (reg.mat.kInf() > 0) fuel_edge = pos;
    }

    const vol = try gpa.alloc(f64, n);
    defer gpa.free(vol);
    const r = try gpa.alloc(f64, n);
    errdefer gpa.free(r);
    for (0..n) |c| {
        vol[c] = geom.volume(edge[c], edge[c + 1]);
        r[c] = 0.5 * (edge[c] + edge[c + 1]);
    }

    // Coupling coefficients per group: cpl[g][c] couples cell c and c+1;
    // cpl[g][n-1] is the vacuum leak term at the outer edge.
    var cpl: [2][]f64 = undefined;
    for (0..2) |g| {
        cpl[g] = try gpa.alloc(f64, n);
    }
    defer for (0..2) |g| gpa.free(cpl[g]);
    for (0..n) |c| {
        const h = edge[c + 1] - edge[c];
        for (0..2) |g| {
            const d = if (g == 0) mat[c].d1 else mat[c].d2;
            if (c + 1 < n) {
                const h2 = edge[c + 2] - edge[c + 1];
                const d2 = if (g == 0) mat[c + 1].d1 else mat[c + 1].d2;
                cpl[g][c] = geom.area(edge[c + 1]) / (h / (2 * d) + h2 / (2 * d2));
            } else {
                cpl[g][c] = geom.area(edge[n]) * d / (h / 2 + 2.13 * d);
            }
        }
    }

    const phi1 = try gpa.alloc(f64, n);
    errdefer gpa.free(phi1);
    const phi2 = try gpa.alloc(f64, n);
    errdefer gpa.free(phi2);
    const src = try gpa.alloc(f64, n);
    defer gpa.free(src);
    const fis = try gpa.alloc(f64, n);
    defer gpa.free(fis);
    const work = try gpa.alloc(f64, 3 * n);
    defer gpa.free(work);

    @memset(phi1, 1);
    @memset(phi2, 1);
    var k: f64 = 1.0;
    var fis_old: f64 = 0;
    for (0..n) |c| {
        fis[c] = (mat[c].nsf1 * phi1[c] + mat[c].nsf2 * phi2[c]) * vol[c];
        fis_old += fis[c];
    }
    if (fis_old == 0) return error.NoFuel;

    var it: u32 = 0;
    while (it < opt.max_iter) : (it += 1) {
        // Fast group.
        for (0..n) |c| src[c] = fis[c] / k;
        solveGroup(mat, vol, cpl[0], src, phi1, work, 0);
        // Thermal group.
        for (0..n) |c| src[c] = mat[c].s12 * phi1[c] * vol[c];
        solveGroup(mat, vol, cpl[1], src, phi2, work, 1);

        var fis_new: f64 = 0;
        var change: f64 = 0;
        for (0..n) |c| {
            const f = (mat[c].nsf1 * phi1[c] + mat[c].nsf2 * phi2[c]) * vol[c];
            fis[c] = f;
            fis_new += f;
        }
        const k_new = k * fis_new / fis_old;
        change = @abs(k_new - k);
        k = k_new;
        // Renormalise to keep numbers tame.
        const s = 1.0 / fis_new;
        for (0..n) |c| {
            fis[c] *= s;
            phi1[c] *= s;
            phi2[c] *= s;
        }
        fis_old = 1.0;
        if (change < opt.tol and it > 5) break;
    }

    // Power shape normalised over fuel.
    const power = try gpa.alloc(f64, n);
    errdefer gpa.free(power);
    var psum: f64 = 0;
    var vsum: f64 = 0;
    var pmax: f64 = 0;
    for (0..n) |c| {
        power[c] = mat[c].sf1 * phi1[c] + mat[c].sf2 * phi2[c];
        if (mat[c].kInf() > 0) {
            psum += power[c] * vol[c];
            vsum += vol[c];
        }
    }
    const mean = psum / vsum;
    for (0..n) |c| {
        power[c] /= mean;
        if (mat[c].kInf() > 0) pmax = @max(pmax, power[c]);
    }
    // Flux scale: thermal flux peak = 1.
    var fmax: f64 = 0;
    for (phi2) |v| fmax = @max(fmax, v);
    for (0..n) |c| {
        phi1[c] /= fmax;
        phi2[c] /= fmax;
    }

    return .{
        .k = k,
        .iterations = it + 1,
        .r = r,
        .phi1 = phi1,
        .phi2 = phi2,
        .power = power,
        .peaking = pmax,
        .fuel_edge = fuel_edge,
    };
}

/// Tridiagonal solve for one group. work holds 3n scratch values.
fn solveGroup(mat: []const Material, vol: []const f64, cpl: []const f64, src: []const f64, phi: []f64, work: []f64, g: usize) void {
    const n = phi.len;
    const a = work[0..n]; // sub
    const b = work[n .. 2 * n]; // diag
    const c = work[2 * n .. 3 * n]; // super
    for (0..n) |i| {
        const rem = if (g == 0) mat[i].sa1 + mat[i].s12 else mat[i].sa2;
        var diag = rem * vol[i] + cpl[i]; // right face (or vacuum)
        if (i > 0) diag += cpl[i - 1];
        b[i] = diag;
        a[i] = if (i > 0) -cpl[i - 1] else 0;
        c[i] = if (i + 1 < n) -cpl[i] else 0;
        phi[i] = src[i];
    }
    // Thomas algorithm, in place.
    for (1..n) |i| {
        const w = a[i] / b[i - 1];
        b[i] -= w * c[i - 1];
        phi[i] -= w * phi[i - 1];
    }
    phi[n - 1] /= b[n - 1];
    var i: usize = n - 1;
    while (i > 0) {
        i -= 1;
        phi[i] = (phi[i] - c[i] * phi[i + 1]) / b[i];
    }
}

/// Bisection on the first region's size for k = target.
pub fn criticalSize(gpa: std.mem.Allocator, geom: Geometry, regions: []Region, target: f64) !f64 {
    var lo: f64 = 1.0;
    var hi: f64 = 1000.0;
    for (0..60) |_| {
        const mid = 0.5 * (lo + hi);
        regions[0].thickness = mid;
        var res = try solve(gpa, geom, regions, .{ .cell_size = @max(0.25, mid / 200), .tol = 1e-9 });
        defer res.deinit(gpa);
        if (res.k < target) lo = mid else hi = mid;
        if (hi - lo < 1e-3) break;
    }
    return 0.5 * (lo + hi);
}

// ---------------------------------------------------------------- tests

// Bare one-group-equivalent check: with no reflector, two-group k for a
// large bare slab approaches k_inf / (1 + M^2 B^2), B = pi / (2 (a + 2.13 D)).
test "bare slab matches modified one-group buckling estimate" {
    const gpa = std.testing.allocator;
    const fuel = materials.lwr_fuel;
    const a = 60.0;
    var res = try solve(gpa, .slab, &.{.{ .mat = fuel, .thickness = a }}, .{ .cell_size = 0.1 });
    defer res.deinit(gpa);
    const ext = a + 2.13 * fuel.d1;
    const b = std.math.pi / (2 * ext);
    const est = fuel.kInf() / ((1 + fuel.d1 / (fuel.sa1 + fuel.s12) * b * b) * (1 + fuel.d2 / fuel.sa2 * b * b));
    try std.testing.expectApproxEqRel(est, res.k, 5e-3);
}

test "reflector raises k" {
    const gpa = std.testing.allocator;
    const fuel = materials.lwr_fuel;
    var bare = try solve(gpa, .sphere, &.{.{ .mat = fuel, .thickness = 30 }}, .{});
    defer bare.deinit(gpa);
    var refl = try solve(gpa, .sphere, &.{ .{ .mat = fuel, .thickness = 30 }, .{ .mat = materials.water, .thickness = 20 } }, .{});
    defer refl.deinit(gpa);
    try std.testing.expect(refl.k > bare.k);
}
