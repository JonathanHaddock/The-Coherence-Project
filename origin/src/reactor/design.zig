//! Reactor designs as data.
//!
//! A design file (JSON) describes one quarter of a square core as a map of
//! assemblies, a legend saying what each map symbol is, optional custom
//! materials, and the constraints the design must meet. The tool builds a
//! mesh from it, solves it, scores it, and can search for a better loading
//! pattern by deterministic pairwise swaps.
//!
//! Map convention: one character per assembly, separated by spaces. The
//! LAST row is the centre row and the FIRST column is the centre column, so
//! the bottom-left symbol is the central assembly (only a quarter of it lies
//! in the modelled quarter). Every assembly is `assembly_cm` square.

const std = @import("std");
const materials = @import("materials.zig");
const d2 = @import("diffusion2d.zig");
const Material = materials.Material;

/// Rod absorber added on top of the assembly's own material (teaching values).
pub const rod_sa1: f64 = 0.004;
pub const rod_sa2: f64 = 0.10;

pub const XS = struct {
    d1: f64,
    d2: f64,
    sa1: f64,
    sa2: f64,
    s12: f64,
    nsf1: f64 = 0,
    nsf2: f64 = 0,
    sf1: f64 = 0,
    sf2: f64 = 0,
};

pub const Symbol = struct {
    /// Built-in material name (lwr, water, graphite) or a key of `materials`.
    mat: []const u8,
    /// Multiplies fission cross sections: a stand-in for enrichment zoning.
    fission_scale: f64 = 1.0,
    /// Extra thermal absorption, 1/cm: a stand-in for burnable absorber.
    extra_sa2: f64 = 0,
    /// Assembly has a control rod channel.
    rod: bool = false,
};

pub const Constraints = struct {
    k_min: ?f64 = null, // rods out (or as set): enough reactivity to run
    k_max: ?f64 = null,
    peaking_max: ?f64 = null,
    shutdown_k_max: ?f64 = null, // all rods fully in
    rod_worth_min_dollars: ?f64 = null,
    axial_offset_abs_max: ?f64 = null, // 3D only
};

pub const Optimize = struct {
    /// Objective to minimise: "peaking", "fuel" (minimise k excess above k_min), or "neg_k".
    objective: []const u8 = "peaking",
    /// Map symbols that may be swapped with each other.
    swappable: []const []const u8 = &.{},
    max_passes: u32 = 20,
};

pub const Spec = struct {
    name: []const u8 = "unnamed",
    notes: []const u8 = "",
    assembly_cm: f64 = 20,
    rod_width_cm: f64 = 4,
    cell_cm: f64 = 2,
    height_cm: f64 = 0,
    axial_reflector_cm: f64 = 20,
    rod_insertion: f64 = 1.0, // as-set insertion for the "as set" state; 0 = rods out
    boron_ppm: f64 = 0,
    materials: std.json.ArrayHashMap(XS) = .{},
    legend: std.json.ArrayHashMap(Symbol),
    map: []const []const u8,
    constraints: Constraints = .{},
    optimize: Optimize = .{},
};

pub const Design = struct {
    spec: Spec,
    /// Parsed map, row 0 = centre row, col 0 = centre column (flipped from file).
    grid: [][]u8,
    na: usize, // assemblies per side

    pub fn deinit(self: *Design, gpa: std.mem.Allocator) void {
        for (self.grid) |row| gpa.free(row);
        gpa.free(self.grid);
    }

    pub fn clone(self: Design, gpa: std.mem.Allocator) !Design {
        const g = try gpa.alloc([]u8, self.na);
        for (self.grid, 0..) |row, i| g[i] = try gpa.dupe(u8, row);
        return .{ .spec = self.spec, .grid = g, .na = self.na };
    }
};

pub fn parse(gpa: std.mem.Allocator, arena: std.mem.Allocator, text: []const u8) !Design {
    const spec = try std.json.parseFromSliceLeaky(Spec, arena, text, .{ .ignore_unknown_fields = false, .allocate = .alloc_always });
    const na = spec.map.len;
    if (na == 0) return error.EmptyMap;
    const grid = try gpa.alloc([]u8, na);
    errdefer gpa.free(grid);
    for (spec.map, 0..) |line, r| {
        var row: std.ArrayList(u8) = .empty;
        var it = std.mem.tokenizeAny(u8, line, " \t");
        while (it.next()) |tok| {
            if (tok.len != 1) return error.MapSymbolsMustBeOneCharacter;
            if (spec.legend.map.get(tok) == null) {
                std.debug.print("  map symbol '{s}' is not in the legend\n", .{tok});
                return error.UnknownMapSymbol;
            }
            try row.append(gpa, tok[0]);
        }
        if (row.items.len != na) {
            std.debug.print("  map row {d} has {d} symbols; the map must be square ({d} x {d})\n", .{ r + 1, row.items.len, na, na });
            return error.MapNotSquare;
        }
        // File row 0 is the top (outermost); grid row 0 is the centre row.
        grid[na - 1 - r] = try row.toOwnedSlice(gpa);
    }
    return .{ .spec = spec, .grid = grid, .na = na };
}

fn resolve(spec: Spec, sym: u8) !Material {
    const key = [1]u8{sym};
    const s = spec.legend.map.get(&key) orelse return error.UnknownMapSymbol;
    var m: Material = blk: {
        if (spec.materials.map.get(s.mat)) |x| break :blk .{
            .name = s.mat,
            .note = "custom",
            .d1 = x.d1,
            .d2 = x.d2,
            .sa1 = x.sa1,
            .sa2 = x.sa2,
            .s12 = x.s12,
            .nsf1 = x.nsf1,
            .nsf2 = x.nsf2,
            .sf1 = x.sf1,
            .sf2 = x.sf2,
        };
        break :blk materials.find(s.mat) orelse {
            std.debug.print("  unknown material '{s}'\n", .{s.mat});
            return error.UnknownMaterial;
        };
    };
    m.nsf1 *= s.fission_scale;
    m.nsf2 *= s.fission_scale;
    m.sf1 *= s.fission_scale;
    m.sf2 *= s.fission_scale;
    m.sa2 += s.extra_sa2;
    return m;
}

fn symbolOf(spec: Spec, sym: u8) Symbol {
    const key = [1]u8{sym};
    return spec.legend.map.get(&key).?;
}

pub const State = struct { insertion: f64 }; // 0 = rods out, 1 = fully in

/// Build the mesh for a design at a given rod insertion and solve it.
pub fn solve(gpa: std.mem.Allocator, des: Design, state: State) !d2.Result {
    const sp = des.spec;
    const A = sp.assembly_cm;
    // Quarter extent: centre assembly contributes half its width.
    const extent = (@as(f64, @floatFromInt(des.na)) - 0.5) * A;
    const n: usize = @max(4, @as(usize, @intFromFloat(@round(extent / sp.cell_cm))));
    const h = extent / @as(f64, @floatFromInt(n));
    const three_d = sp.height_cm > 0;
    const z_extent = if (three_d) sp.height_cm + 2 * sp.axial_reflector_cm else 0;
    const nz: usize = if (three_d) @max(4, @as(usize, @intFromFloat(@round(z_extent / sp.cell_cm)))) else 1;
    const hz = if (three_d) z_extent / @as(f64, @floatFromInt(nz)) else 1;
    const nn = n * n * nz;

    // Pre-resolve each map symbol once.
    var cache: [128]?Material = @splat(null);
    for (des.grid) |row| for (row) |c| {
        if (cache[c] == null) cache[c] = try resolve(sp, c);
    };
    var refl_m = materials.water;
    // Axial reflector: the first non-fissile legend material, else water.
    for (sp.legend.map.values()) |s| {
        const m = materials.find(s.mat) orelse continue;
        if (m.kInf() == 0) {
            refl_m = m;
            break;
        }
    }
    refl_m.sa2 += sp.boron_ppm * d2.boron_sa2_per_ppm;

    const kind = try gpa.alloc(d2.Kind, nn);
    errdefer gpa.free(kind);
    const mats = try gpa.alloc(Material, nn);
    defer gpa.free(mats);
    const half = @max(sp.rod_width_cm / 2, sp.cell_cm / 2 * 1.001);
    for (0..nz) |k| for (0..n) |j| for (0..n) |i| {
        const x = (@as(f64, @floatFromInt(i)) + 0.5) * h;
        const y = (@as(f64, @floatFromInt(j)) + 0.5) * h;
        const z = (@as(f64, @floatFromInt(k)) + 0.5) * hz;
        const c = (k * n + j) * n + i;
        const ai = @min(des.na - 1, @as(usize, @intFromFloat(@floor(x / A + 0.5))));
        const aj = @min(des.na - 1, @as(usize, @intFromFloat(@floor(y / A + 0.5))));
        const sym = des.grid[aj][ai];
        var m = cache[sym].?;
        const axial_refl = three_d and (z < sp.axial_reflector_cm or z > sp.axial_reflector_cm + sp.height_cm);
        if (axial_refl) {
            mats[c] = refl_m;
            kind[c] = .reflector;
            continue;
        }
        // Boron is in all coolant: fuel lattices and water.
        if (m.kInf() > 0 or std.mem.eql(u8, m.name, "water")) m.sa2 += sp.boron_ppm * d2.boron_sa2_per_ppm;
        kind[c] = if (m.kInf() > 0) .fuel else .reflector;
        const s = symbolOf(sp, sym);
        if (s.rod and state.insertion > 0) {
            const cx = @as(f64, @floatFromInt(ai)) * A;
            const cy = @as(f64, @floatFromInt(aj)) * A;
            if (@abs(x - cx) < half and @abs(y - cy) < half) {
                const tip = sp.axial_reflector_cm + sp.height_cm * (1 - state.insertion);
                if (!three_d or z > tip) {
                    m.sa1 += rod_sa1;
                    m.sa2 += rod_sa2;
                    kind[c] = .rod;
                }
            }
        }
        mats[c] = m;
    };
    return d2.solveMesh(gpa, .{ .n = n, .nz = nz, .h = h, .hz = hz }, kind, mats);
}

pub const Check = struct { name: []const u8, value: f64, limit: f64, upper: bool, pass: bool };

pub const Score = struct {
    k_out: f64,
    k_set: f64,
    k_in: f64,
    peaking: f64, // at the as-set state
    worth_dollars: f64,
    axial_offset: ?f64,
    fuel_fraction: f64, // fuel assemblies / all assemblies
    checks: [6]?Check,
    pass: bool,

    pub fn objective(self: Score, name: []const u8, c: Constraints) f64 {
        // Infeasible designs are pushed far away, by how much they miss.
        var penalty: f64 = 0;
        for (self.checks) |ch| if (ch) |x| {
            if (!x.pass) penalty += 1000 * @abs(x.value - x.limit) / @max(@abs(x.limit), 1e-6);
        };
        if (std.mem.eql(u8, name, "peaking")) return self.peaking + penalty;
        if (std.mem.eql(u8, name, "neg_k")) return -self.k_out + penalty;
        if (std.mem.eql(u8, name, "fuel")) return (self.k_out - (c.k_min orelse 1.0)) + penalty;
        return self.peaking + penalty;
    }
};

pub fn score(gpa: std.mem.Allocator, des: Design) !Score {
    const sp = des.spec;
    // Solve only the rod states that are distinct: as-set equals out at 0
    // insertion and equals in at full insertion.
    var r_out = try solve(gpa, des, .{ .insertion = 0 });
    defer r_out.deinit(gpa);
    var r_in = try solve(gpa, des, .{ .insertion = 1 });
    defer r_in.deinit(gpa);
    const ins = sp.rod_insertion;
    var r_mid: ?d2.Result = if (ins > 0 and ins < 1) try solve(gpa, des, .{ .insertion = ins }) else null;
    defer if (r_mid) |*m| m.deinit(gpa);
    const r_set = if (r_mid) |m| m else if (ins >= 1) r_in else r_out;
    const beta = 0.0065;
    const worth = (1 / r_in.k - 1 / r_out.k) / beta;
    const ao: ?f64 = if (r_set.nz > 1) try r_set.axialOffset(gpa) else null;

    var fuel: f64 = 0;
    for (des.grid) |row| for (row) |c| {
        if ((try resolve(sp, c)).kInf() > 0) fuel += 1;
    };
    const total = @as(f64, @floatFromInt(des.na * des.na));

    const c = sp.constraints;
    var checks: [6]?Check = @splat(null);
    if (c.k_min) |v| checks[0] = .{ .name = "k_eff rods out >=", .value = r_out.k, .limit = v, .upper = false, .pass = r_out.k >= v };
    if (c.k_max) |v| checks[1] = .{ .name = "k_eff rods out <=", .value = r_out.k, .limit = v, .upper = true, .pass = r_out.k <= v };
    if (c.peaking_max) |v| checks[2] = .{ .name = "peaking <=", .value = r_set.peaking, .limit = v, .upper = true, .pass = r_set.peaking <= v };
    if (c.shutdown_k_max) |v| checks[3] = .{ .name = "k_eff all rods in <=", .value = r_in.k, .limit = v, .upper = true, .pass = r_in.k <= v };
    if (c.rod_worth_min_dollars) |v| checks[4] = .{ .name = "rod worth ($) >=", .value = worth, .limit = v, .upper = false, .pass = worth >= v };
    if (c.axial_offset_abs_max) |v| if (ao) |a| {
        checks[5] = .{ .name = "|axial offset| <=", .value = @abs(a), .limit = v, .upper = true, .pass = @abs(a) <= v };
    };
    var pass = true;
    for (checks) |ch| if (ch) |x| {
        if (!x.pass) pass = false;
    };
    return .{
        .k_out = r_out.k,
        .k_set = r_set.k,
        .k_in = r_in.k,
        .peaking = r_set.peaking,
        .worth_dollars = worth,
        .axial_offset = ao,
        .fuel_fraction = fuel / total,
        .checks = checks,
        .pass = pass,
    };
}

pub const Step = struct { pass: u32, a: [2]usize, b: [2]usize, objective: f64 };

/// Deterministic steepest-descent over pairwise swaps of swappable symbols.
/// Visits every pair in a fixed order each pass, applies the single best
/// improving swap, and stops when no swap improves. Modifies `des` in place.
pub fn optimize(gpa: std.mem.Allocator, des: *Design, log: *std.ArrayList(Step)) !Score {
    const sp = des.spec;
    const opt = sp.optimize;
    var movable: std.ArrayList([2]usize) = .empty;
    defer movable.deinit(gpa);
    for (des.grid, 0..) |row, j| for (row, 0..) |c, i| {
        for (opt.swappable) |s| if (s.len == 1 and s[0] == c) {
            try movable.append(gpa, .{ i, j });
            break;
        };
    };
    var best = try score(gpa, des.*);
    var best_obj = best.objective(opt.objective, sp.constraints);
    var p: u32 = 0;
    while (p < opt.max_passes) : (p += 1) {
        var cand: ?[2][2]usize = null;
        var cand_obj = best_obj;
        var cand_score = best;
        const m = movable.items;
        for (0..m.len) |x| for (x + 1..m.len) |y| {
            const a = m[x];
            const b = m[y];
            if (des.grid[a[1]][a[0]] == des.grid[b[1]][b[0]]) continue;
            std.mem.swap(u8, &des.grid[a[1]][a[0]], &des.grid[b[1]][b[0]]);
            const s = try score(gpa, des.*);
            const o = s.objective(opt.objective, sp.constraints);
            std.mem.swap(u8, &des.grid[a[1]][a[0]], &des.grid[b[1]][b[0]]);
            if (o < cand_obj - 1e-9) {
                cand_obj = o;
                cand = .{ a, b };
                cand_score = s;
            }
        };
        const sw = cand orelse break;
        std.mem.swap(u8, &des.grid[sw[0][1]][sw[0][0]], &des.grid[sw[1][1]][sw[1][0]]);
        best = cand_score;
        best_obj = cand_obj;
        try log.append(gpa, .{ .pass = p + 1, .a = sw[0], .b = sw[1], .objective = cand_obj });
    }
    return best;
}

/// Write the design back out as JSON with the current map. Caller frees.
pub fn toJson(gpa: std.mem.Allocator, des: Design) ![]u8 {
    var sp = des.spec;
    const rows = try gpa.alloc([]const u8, des.na);
    defer {
        for (rows) |r| gpa.free(r);
        gpa.free(rows);
    }
    for (0..des.na) |r| {
        const src = des.grid[des.na - 1 - r];
        const line = try gpa.alloc(u8, des.na * 2 - 1);
        for (src, 0..) |c, i| {
            line[2 * i] = c;
            if (i + 1 < src.len) line[2 * i + 1] = ' ';
        }
        rows[r] = line;
    }
    sp.map = rows;
    var out: std.Io.Writer.Allocating = .init(gpa);
    errdefer out.deinit();
    try std.json.Stringify.value(sp, .{ .whitespace = .indent_2, .emit_null_optional_fields = false }, &out.writer);
    try out.writer.writeAll("\n");
    return out.toOwnedSlice();
}

// ---------------------------------------------------------------- tests

const sample =
    \\{
    \\  "name": "test",
    \\  "cell_cm": 4,
    \\  "legend": {
    \\    "F": { "mat": "lwr" },
    \\    "H": { "mat": "lwr", "fission_scale": 1.1 },
    \\    "C": { "mat": "lwr", "rod": true },
    \\    "W": { "mat": "water" }
    \\  },
    \\  "map": [
    \\    "W W W W",
    \\    "F F H W",
    \\    "H F F W",
    \\    "C F H W"
    \\  ],
    \\  "constraints": { "k_min": 1.0 },
    \\  "optimize": { "swappable": ["F", "H"], "max_passes": 3 }
    \\}
;

test "design matches the equivalent built-in layout" {
    const gpa = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const text =
        \\{ "cell_cm": 2, "legend": { "F": { "mat": "lwr" }, "W": { "mat": "water" } },
        \\  "map": [ "W W W W W", "F F F F W", "F F F F W", "F F F F W", "F F F F W" ] }
    ;
    var des = try parse(gpa, arena.allocator(), text);
    defer des.deinit(gpa);
    var r = try solve(gpa, des, .{ .insertion = 0 });
    defer r.deinit(gpa);
    // Same as Layout{ half_width = 70, reflector = 20 }.
    var ref = try d2.solve(gpa, .{ .half_width = 70, .reflector = 20, .cell = 2 });
    defer ref.deinit(gpa);
    try std.testing.expectApproxEqRel(ref.k, r.k, 2e-3);
}

test "optimizer never makes the objective worse and round-trips JSON" {
    const gpa = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    var des = try parse(gpa, arena.allocator(), sample);
    defer des.deinit(gpa);
    const before = try score(gpa, des);
    var log: std.ArrayList(Step) = .empty;
    defer log.deinit(gpa);
    const after = try optimize(gpa, &des, &log);
    try std.testing.expect(after.peaking <= before.peaking + 1e-12);
    const js = try toJson(gpa, des);
    defer gpa.free(js);
    var des2 = try parse(gpa, arena.allocator(), js);
    defer des2.deinit(gpa);
    for (des.grid, des2.grid) |a, b| try std.testing.expectEqualStrings(a, b);
}
