//! Two-group neutron diffusion on a Cartesian mesh: 2D (x-y) or 3D (x-y-z).
//!
//! Models one quarter of a square core: symmetry (zero current) on the
//! x = 0 and y = 0 faces, vacuum on the outer x and y faces. In 3D the core
//! has an active height with axial reflectors top and bottom (vacuum beyond
//! them) and rods enter from the top, inserted a chosen fraction of the
//! active height. In 2D (height = 0) the core is infinitely tall.
//!
//! Soluble boron in the coolant adds thermal absorption to every water-
//! bearing material (fuel lattice, rodded lattice, water reflector).
//!
//! Power iteration on the fission source; each group is solved with
//! successive over-relaxation.

const std = @import("std");
const materials = @import("materials.zig");
const Material = materials.Material;

/// Added thermal absorption per ppm of natural boron (1/cm per ppm).
/// Illustrative: gives roughly 10 pcm/ppm, the order of a real PWR.
pub const boron_sa2_per_ppm: f64 = 8.0e-6;

pub const RodPattern = enum {
    out,
    all,
    center,
    ring,
    checker,

    pub fn parse(s: []const u8) ?RodPattern {
        var buf: [16]u8 = undefined;
        if (s.len > buf.len) return null;
        return std.meta.stringToEnum(RodPattern, std.ascii.lowerString(&buf, s));
    }

    fn has(p: RodPattern, ai: usize, aj: usize) bool {
        return switch (p) {
            .out => false,
            .all => true,
            .center => ai == 0 and aj == 0,
            .ring => @max(ai, aj) == 1,
            .checker => (ai + aj) % 2 == 0,
        };
    }
};

pub const Layout = struct {
    half_width: f64 = 60, // fuel half-width, cm
    reflector: f64 = 20, // radial reflector, cm
    refl_mat: Material = materials.water,
    assembly: f64 = 20, // assembly pitch, cm
    rod_width: f64 = 4, // full width of a rod channel, cm
    rods: RodPattern = .out,
    cell: f64 = 1.0, // mesh size, cm
    height: f64 = 0, // active height, cm; 0 = 2D (infinitely tall)
    axial_reflector: f64 = 20, // cm, top and bottom (3D only)
    insertion: f64 = 1.0, // rod insertion, fraction of active height from the top
    boron_ppm: f64 = 0,
};

pub const Kind = enum(u8) { fuel, rod, reflector };

pub const Result = struct {
    k: f64,
    outer: u32,
    n: usize,
    nz: usize,
    h: f64,
    hz: f64,
    z_active: [2]usize,
    kind: []Kind,
    phi1: []f64,
    phi2: []f64,
    power: []f64,
    peaking: f64,

    pub fn deinit(self: *Result, gpa: std.mem.Allocator) void {
        gpa.free(self.kind);
        gpa.free(self.phi1);
        gpa.free(self.phi2);
        gpa.free(self.power);
    }

    pub fn idx(self: Result, i: usize, j: usize, k: usize) usize {
        return (k * self.n + j) * self.n + i;
    }

    /// Mean fuel power in each active z cell, bottom to top. Caller frees.
    pub fn axialPower(self: Result, gpa: std.mem.Allocator) ![]f64 {
        const za = self.z_active;
        const out = try gpa.alloc(f64, za[1] - za[0]);
        for (za[0]..za[1]) |k| {
            var s: f64 = 0;
            var c: f64 = 0;
            for (0..self.n) |j| for (0..self.n) |i| {
                const q = self.idx(i, j, k);
                if (self.kind[q] != .reflector) {
                    s += self.power[q];
                    c += 1;
                }
            };
            out[k - za[0]] = s / c;
        }
        return out;
    }

    /// Axial offset (P_top - P_bottom) / (P_top + P_bottom).
    pub fn axialOffset(self: Result, gpa: std.mem.Allocator) !f64 {
        const ap = try self.axialPower(gpa);
        defer gpa.free(ap);
        var lo: f64 = 0;
        var hi: f64 = 0;
        const half = ap.len / 2;
        for (ap, 0..) |v, i| {
            if (i < half) lo += v else hi += v;
        }
        return (hi - lo) / (hi + lo);
    }
};

fn classify(l: Layout, x: f64, y: f64, z: f64) Kind {
    if (x > l.half_width or y > l.half_width) return .reflector;
    if (l.height > 0) {
        if (z < l.axial_reflector or z > l.axial_reflector + l.height) return .reflector;
    }
    const ai: usize = @intFromFloat(@floor(x / l.assembly + 0.5));
    const aj: usize = @intFromFloat(@floor(y / l.assembly + 0.5));
    const cx = @as(f64, @floatFromInt(ai)) * l.assembly;
    const cy = @as(f64, @floatFromInt(aj)) * l.assembly;
    if (cx + l.rod_width / 2 > l.half_width or cy + l.rod_width / 2 > l.half_width) return .fuel;
    // A rod covers at least the cell nearest its centre, however coarse the mesh.
    const half = @max(l.rod_width / 2, l.cell / 2 * 1.001);
    if (@abs(x - cx) < half and @abs(y - cy) < half and l.rods.has(ai, aj)) {
        if (l.height == 0) return if (l.insertion > 0) .rod else .fuel;
        const tip = l.axial_reflector + l.height * (1 - l.insertion);
        if (z > tip) return .rod;
    }
    return .fuel;
}

fn matOf(l: Layout, k: Kind) Material {
    var m = switch (k) {
        .fuel => materials.lwr_fuel,
        .rod => materials.rodded,
        .reflector => l.refl_mat,
    };
    if (k != .reflector or std.mem.eql(u8, m.name, "water")) m.sa2 += l.boron_ppm * boron_sa2_per_ppm;
    return m;
}

pub fn solve(gpa: std.mem.Allocator, l: Layout) !Result {
    const extent = l.half_width + l.reflector;
    const n: usize = @max(4, @as(usize, @intFromFloat(@round(extent / l.cell))));
    const h = extent / @as(f64, @floatFromInt(n));
    const three_d = l.height > 0;
    const z_extent = if (three_d) l.height + 2 * l.axial_reflector else 0;
    const nz: usize = if (three_d) @max(4, @as(usize, @intFromFloat(@round(z_extent / l.cell)))) else 1;
    const hz = if (three_d) z_extent / @as(f64, @floatFromInt(nz)) else 1;
    const nn = n * n * nz;

    const kind = try gpa.alloc(Kind, nn);
    errdefer gpa.free(kind);
    var za = [2]usize{ nz, 0 };
    for (0..nz) |k| for (0..n) |j| for (0..n) |i| {
        const x = (@as(f64, @floatFromInt(i)) + 0.5) * h;
        const y = (@as(f64, @floatFromInt(j)) + 0.5) * h;
        const z = (@as(f64, @floatFromInt(k)) + 0.5) * hz;
        const c = (k * n + j) * n + i;
        kind[c] = classify(l, x, y, if (three_d) z else 0);
        if (i == 0 and j == 0 and kind[c] != .reflector) {
            za[0] = @min(za[0], k);
            za[1] = @max(za[1], k + 1);
        }
    };

    const buf = try gpa.alloc(f64, nn * 9);
    defer gpa.free(buf);
    const d = [2][]f64{ buf[0..nn], buf[nn .. 2 * nn] };
    const rem = [2][]f64{ buf[2 * nn .. 3 * nn], buf[3 * nn .. 4 * nn] };
    const s12 = buf[4 * nn .. 5 * nn];
    const nsf = [2][]f64{ buf[5 * nn .. 6 * nn], buf[6 * nn .. 7 * nn] };
    const src = buf[7 * nn .. 8 * nn];
    const fis = buf[8 * nn .. 9 * nn];
    for (0..nn) |c| {
        const m = matOf(l, kind[c]);
        d[0][c] = m.d1;
        d[1][c] = m.d2;
        rem[0][c] = m.sa1 + m.s12;
        rem[1][c] = m.sa2;
        s12[c] = m.s12;
        nsf[0][c] = m.nsf1;
        nsf[1][c] = m.nsf2;
    }

    const phi1 = try gpa.alloc(f64, nn);
    errdefer gpa.free(phi1);
    const phi2 = try gpa.alloc(f64, nn);
    errdefer gpa.free(phi2);
    @memset(phi1, 1);
    @memset(phi2, 1);
    const phi = [2][]f64{ phi1, phi2 };

    var k: f64 = 1;
    var total: f64 = 0;
    for (0..nn) |c| {
        fis[c] = nsf[0][c] * phi1[c] + nsf[1][c] * phi2[c];
        total += fis[c];
    }

    const mesh = Mesh{ .n = n, .nz = nz, .h = h, .hz = hz };
    var outer: u32 = 0;
    while (outer < 3000) : (outer += 1) {
        for (0..2) |g| {
            if (g == 0) {
                for (0..nn) |c| src[c] = fis[c] / k;
            } else {
                for (0..nn) |c| src[c] = s12[c] * phi1[c];
            }
            sor(mesh, d[g], rem[g], src, phi[g], 12);
        }
        var new_total: f64 = 0;
        for (0..nn) |c| {
            fis[c] = nsf[0][c] * phi1[c] + nsf[1][c] * phi2[c];
            new_total += fis[c];
        }
        const k_new = k * new_total / total;
        const dk = @abs(k_new - k);
        k = k_new;
        const s = 1.0 / new_total;
        for (0..nn) |c| {
            fis[c] *= s;
            phi1[c] *= s;
            phi2[c] *= s;
        }
        total = 1;
        if (dk < 1e-8 and outer > 20) break;
    }

    const power = try gpa.alloc(f64, nn);
    errdefer gpa.free(power);
    var psum: f64 = 0;
    var cnt: f64 = 0;
    for (0..nn) |c| {
        const m = matOf(l, kind[c]);
        power[c] = m.sf1 * phi1[c] + m.sf2 * phi2[c];
        if (kind[c] != .reflector) {
            psum += power[c];
            cnt += 1;
        }
    }
    var pmax: f64 = 0;
    for (0..nn) |c| {
        power[c] /= psum / cnt;
        if (kind[c] != .reflector) pmax = @max(pmax, power[c]);
    }
    var fmax: f64 = 0;
    for (phi2) |v| fmax = @max(fmax, v);
    for (0..nn) |c| {
        phi1[c] /= fmax;
        phi2[c] /= fmax;
    }

    return .{ .k = k, .outer = outer + 1, .n = n, .nz = nz, .h = h, .hz = hz, .z_active = za, .kind = kind, .phi1 = phi1, .phi2 = phi2, .power = power, .peaking = pmax };
}

/// Bisection on boron for k = target. Null if k < target with no boron.
pub fn criticalBoron(gpa: std.mem.Allocator, l: Layout, target: f64) !?f64 {
    var lay = l;
    lay.boron_ppm = 0;
    var r0 = try solve(gpa, lay);
    const k0 = r0.k;
    r0.deinit(gpa);
    if (k0 < target) return null;
    var lo: f64 = 0;
    var hi: f64 = 4000;
    for (0..40) |_| {
        const mid = 0.5 * (lo + hi);
        lay.boron_ppm = mid;
        var r = try solve(gpa, lay);
        defer r.deinit(gpa);
        if (r.k > target) lo = mid else hi = mid;
        if (hi - lo < 0.5) break;
    }
    return 0.5 * (lo + hi);
}

const Mesh = struct { n: usize, nz: usize, h: f64, hz: f64 };

fn coupling(da: f64, db: f64, step2: f64) f64 {
    return 2 * da * db / (da + db) / step2;
}

fn vacuum(dc: f64, step: f64) f64 {
    return dc / (step / 2 + 2.13 * dc) / step;
}

fn sor(m: Mesh, d: []const f64, rem: []const f64, src: []const f64, phi: []f64, sweeps: usize) void {
    const omega = 1.6;
    const n = m.n;
    const plane = n * n;
    const h2 = m.h * m.h;
    const hz2 = m.hz * m.hz;
    for (0..sweeps) |_| {
        for (0..m.nz) |k| for (0..n) |j| for (0..n) |i| {
            const c = (k * n + j) * n + i;
            var diag = rem[c];
            var off: f64 = 0;
            if (i > 0) {
                const a = coupling(d[c], d[c - 1], h2);
                diag += a;
                off += a * phi[c - 1];
            }
            if (i + 1 < n) {
                const a = coupling(d[c], d[c + 1], h2);
                diag += a;
                off += a * phi[c + 1];
            } else diag += vacuum(d[c], m.h);
            if (j > 0) {
                const a = coupling(d[c], d[c - n], h2);
                diag += a;
                off += a * phi[c - n];
            }
            if (j + 1 < n) {
                const a = coupling(d[c], d[c + n], h2);
                diag += a;
                off += a * phi[c + n];
            } else diag += vacuum(d[c], m.h);
            if (m.nz > 1) {
                if (k > 0) {
                    const a = coupling(d[c], d[c - plane], hz2);
                    diag += a;
                    off += a * phi[c - plane];
                } else diag += vacuum(d[c], m.hz);
                if (k + 1 < m.nz) {
                    const a = coupling(d[c], d[c + plane], hz2);
                    diag += a;
                    off += a * phi[c + plane];
                } else diag += vacuum(d[c], m.hz);
            }
            const gs = (src[c] + off) / diag;
            phi[c] += omega * (gs - phi[c]);
        };
    }
}

// ---------------------------------------------------------------- tests

fn analyticBare(a: f64, height: f64) f64 {
    const f = materials.lwr_fuel;
    const ext = a + 2.13 * f.d1;
    var b2 = 2 * std.math.pow(f64, std.math.pi / (2 * ext), 2);
    if (height > 0) b2 += std.math.pow(f64, std.math.pi / (height + 2 * 2.13 * f.d1), 2);
    return f.kInf() / ((1 + f.d1 / (f.sa1 + f.s12) * b2) * (1 + f.d2 / f.sa2 * b2));
}

test "bare square core matches the analytic two-group buckling result" {
    const gpa = std.testing.allocator;
    var r = try solve(gpa, .{ .half_width = 40, .reflector = 0, .cell = 0.5 });
    defer r.deinit(gpa);
    try std.testing.expectApproxEqRel(analyticBare(40, 0), r.k, 5e-3);
}

test "bare 3D box matches the analytic buckling result" {
    const gpa = std.testing.allocator;
    var r = try solve(gpa, .{ .half_width = 40, .reflector = 0, .height = 100, .axial_reflector = 0, .cell = 2.0 });
    defer r.deinit(gpa);
    try std.testing.expectApproxEqRel(analyticBare(40, 100), r.k, 1e-2);
}

test "inserting rods lowers k" {
    const gpa = std.testing.allocator;
    var a = try solve(gpa, .{ .cell = 2.0 });
    defer a.deinit(gpa);
    var b = try solve(gpa, .{ .cell = 2.0, .rods = .all });
    defer b.deinit(gpa);
    try std.testing.expect(b.k < a.k - 0.01);
}

test "boron worth is roughly 10 pcm per ppm" {
    const gpa = std.testing.allocator;
    var a = try solve(gpa, .{ .cell = 2.0 });
    defer a.deinit(gpa);
    var b = try solve(gpa, .{ .cell = 2.0, .boron_ppm = 100 });
    defer b.deinit(gpa);
    const pcm_per_ppm = (1 / b.k - 1 / a.k) * 1e5 / 100;
    try std.testing.expect(pcm_per_ppm > 5 and pcm_per_ppm < 20);
}

test "half-inserted rods push power to the bottom" {
    const gpa = std.testing.allocator;
    var r = try solve(gpa, .{ .cell = 4.0, .height = 120, .rods = .all, .insertion = 0.5 });
    defer r.deinit(gpa);
    try std.testing.expect(try r.axialOffset(gpa) < -0.05);
}
