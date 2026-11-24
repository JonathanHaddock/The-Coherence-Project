//! Two-dimensional two-group neutron diffusion on a square mesh (x-y).
//!
//! Models one quarter of a square core: symmetry (zero current) on the
//! x = 0 and y = 0 faces, vacuum on the outer faces (flux extrapolated to
//! zero 2.13 D beyond the surface). Each mesh cell holds one homogenized
//! material. Power iteration on the fission source; each group is solved
//! with successive over-relaxation.

const std = @import("std");
const materials = @import("materials.zig");
const Material = materials.Material;

pub const RodPattern = enum {
    out, // all rods withdrawn
    all, // a rod in every assembly
    center, // central assembly only
    ring, // the first ring around the centre
    checker, // alternating assemblies

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
    reflector: f64 = 20, // cm
    refl_mat: Material = materials.water,
    assembly: f64 = 20, // assembly pitch, cm
    rod_width: f64 = 4, // full width of a rod channel, cm
    rods: RodPattern = .out,
    cell: f64 = 1.0, // mesh size, cm
};

pub const Kind = enum(u8) { fuel, rod, reflector };

pub const Result = struct {
    k: f64,
    outer: u32,
    n: usize, // cells per side
    h: f64,
    kind: []Kind,
    phi1: []f64,
    phi2: []f64,
    power: []f64, // fission rate, mean over fuel = 1
    peaking: f64,

    pub fn deinit(self: *Result, gpa: std.mem.Allocator) void {
        gpa.free(self.kind);
        gpa.free(self.phi1);
        gpa.free(self.phi2);
        gpa.free(self.power);
    }
};

/// Material of the cell whose centre is at (x, y), quarter-core coordinates.
fn classify(l: Layout, x: f64, y: f64) Kind {
    if (x > l.half_width or y > l.half_width) return .reflector;
    // Assembly index: assembly 0 is centred on the origin.
    const ai: usize = @intFromFloat(@floor(x / l.assembly + 0.5));
    const aj: usize = @intFromFloat(@floor(y / l.assembly + 0.5));
    const cx = @as(f64, @floatFromInt(ai)) * l.assembly;
    const cy = @as(f64, @floatFromInt(aj)) * l.assembly;
    if (cx + l.rod_width / 2 > l.half_width or cy + l.rod_width / 2 > l.half_width) return .fuel;
    if (@abs(x - cx) < l.rod_width / 2 and @abs(y - cy) < l.rod_width / 2 and l.rods.has(ai, aj)) return .rod;
    return .fuel;
}

fn matOf(l: Layout, k: Kind) Material {
    return switch (k) {
        .fuel => materials.lwr_fuel,
        .rod => materials.rodded,
        .reflector => l.refl_mat,
    };
}

pub fn solve(gpa: std.mem.Allocator, l: Layout) !Result {
    const extent = l.half_width + l.reflector;
    const n: usize = @intFromFloat(@round(extent / l.cell));
    const h = extent / @as(f64, @floatFromInt(n));
    const nn = n * n;

    const kind = try gpa.alloc(Kind, nn);
    errdefer gpa.free(kind);
    for (0..n) |j| for (0..n) |i| {
        const x = (@as(f64, @floatFromInt(i)) + 0.5) * h;
        const y = (@as(f64, @floatFromInt(j)) + 0.5) * h;
        kind[j * n + i] = classify(l, x, y);
    };

    // Per-cell constants.
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

    const h2 = h * h;
    var outer: u32 = 0;
    while (outer < 3000) : (outer += 1) {
        for (0..2) |g| {
            if (g == 0) {
                for (0..nn) |c| src[c] = fis[c] / k;
            } else {
                for (0..nn) |c| src[c] = s12[c] * phi1[c];
            }
            sor(n, h, h2, d[g], rem[g], src, phi[g], 12);
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

    return .{ .k = k, .outer = outer + 1, .n = n, .h = h, .kind = kind, .phi1 = phi1, .phi2 = phi2, .power = power, .peaking = pmax };
}

fn coupling(da: f64, db: f64, h2: f64) f64 {
    return 2 * da * db / (da + db) / h2;
}

fn sor(n: usize, h: f64, h2: f64, d: []const f64, rem: []const f64, src: []const f64, phi: []f64, sweeps: usize) void {
    const omega = 1.6;
    for (0..sweeps) |_| {
        for (0..n) |j| for (0..n) |i| {
            const c = j * n + i;
            var diag = rem[c];
            var off: f64 = 0;
            // west (symmetry at i = 0)
            if (i > 0) {
                const a = coupling(d[c], d[c - 1], h2);
                diag += a;
                off += a * phi[c - 1];
            }
            // east (vacuum at i = n-1)
            if (i + 1 < n) {
                const a = coupling(d[c], d[c + 1], h2);
                diag += a;
                off += a * phi[c + 1];
            } else diag += d[c] / (h / 2 + 2.13 * d[c]) / h;
            // south (symmetry at j = 0)
            if (j > 0) {
                const a = coupling(d[c], d[c - n], h2);
                diag += a;
                off += a * phi[c - n];
            }
            // north (vacuum)
            if (j + 1 < n) {
                const a = coupling(d[c], d[c + n], h2);
                diag += a;
                off += a * phi[c + n];
            } else diag += d[c] / (h / 2 + 2.13 * d[c]) / h;
            const gs = (src[c] + off) / diag;
            phi[c] += omega * (gs - phi[c]);
        };
    }
}

// ---------------------------------------------------------------- tests

test "bare square core matches the analytic two-group buckling result" {
    const gpa = std.testing.allocator;
    const f = materials.lwr_fuel;
    const a = 40.0;
    var r = try solve(gpa, .{ .half_width = a, .reflector = 0, .cell = 0.5 });
    defer r.deinit(gpa);
    const ext = a + 2.13 * f.d1;
    const b2 = 2 * std.math.pow(f64, std.math.pi / (2 * ext), 2);
    const est = f.kInf() / ((1 + f.d1 / (f.sa1 + f.s12) * b2) * (1 + f.d2 / f.sa2 * b2));
    try std.testing.expectApproxEqRel(est, r.k, 5e-3);
}

test "inserting rods lowers k" {
    const gpa = std.testing.allocator;
    var a = try solve(gpa, .{ .cell = 2.0 });
    defer a.deinit(gpa);
    var b = try solve(gpa, .{ .cell = 2.0, .rods = .all });
    defer b.deinit(gpa);
    try std.testing.expect(b.k < a.k - 0.01);
}
