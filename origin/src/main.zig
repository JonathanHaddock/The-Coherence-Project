const std = @import("std");
const detector = @import("visualization/detector.zig");

const constants = @import("science/constants.zig");
const units = @import("science/units.zig");
const particles = @import("science/particles.zig");
const observations = @import("science/observations.zig");
const koide = @import("analysis/koide.zig");
const projector = @import("analysis/projector.zig");
const kinematics = @import("analysis/kinematics.zig");
const manifest = @import("dataset/manifest.zig");
const events = @import("dataset/events.zig");
const store = @import("dataset/store.zig");
const spectrum = @import("analysis/spectrum.zig");
const spectrum_svg = @import("visualization/spectrum_svg.zig");
const projector_svg = @import("visualization/projector_svg.zig");

test {
    _ = koide;
    _ = projector;
    _ = kinematics;
    _ = manifest;
    _ = events;
    _ = store;
    _ = spectrum;
    _ = detector;
    _ = projector_svg;
}

fn header() void {
    std.debug.print(
        \\
        \\========================================
        \\                 ORIGIN
        \\       PARTICLE OBSERVATION ENGINE
        \\========================================
        \\
    , .{});
}

fn help() void {
    std.debug.print(
        \\
        \\USAGE:
        \\  origin info
        \\  origin science
        \\  origin catalogue
        \\  origin constants
        \\  origin observe <particle>
        \\  origin dataset
        \\  origin analyze [dataset]
        \\  origin koide
        \\  origin project [a b c]
        \\  origin chart [a b c] [--no-open]
        \\  origin app [--no-open]
        \\  origin display [dataset] [event]
        \\  origin help
        \\
    , .{});
}

fn info() void {
    std.debug.print(
        \\
        \\ORIGIN SYSTEM INFORMATION
        \\
        \\Version:       0.4.0
        \\Language:      Zig 0.17.0
        \\Platform:      macOS
        \\Storage:       Local
        \\Interface:     Terminal
        \\
        \\Scientific modules: ONLINE
        \\Particle catalogue: ONLINE
        \\Dataset engine:     ONLINE (CMS open data, adler32 verified)
        \\Analysis engine:    ONLINE (Koide, invariant mass)
        \\Event display:      ONLINE
        \\
    , .{});
}

fn catalogue() void {
    std.debug.print(
        \\
        \\========================================
        \\          PARTICLE CATALOGUE
        \\========================================
        \\
    , .{});

    for (std.enums.values(particles.Family)) |family| {
        std.debug.print("\n{s}\n", .{family.label()});
        for (particles.catalogue) |p| {
            if (p.family == family) std.debug.print("  {s:<9} {s}\n", .{ p.name, p.symbol });
        }
    }

    std.debug.print("\nTotal registered particles: {d}\n", .{particles.catalogue.len});
}

fn printConstants() void {
    std.debug.print(
        \\
        \\========================================
        \\          PHYSICAL CONSTANTS
        \\========================================
        \\
        \\Speed of light:       {} m/s
        \\Planck constant:      {} J*s
        \\Elementary charge:    {} C
        \\Electron mass:        {} kg
        \\Proton mass:          {} kg
        \\Neutron mass:         {} kg
        \\Gravitational const:  {}
        \\Boltzmann constant:   {}
        \\Avogadro constant:    {}
        \\
    , .{
        constants.speed_of_light,
        constants.planck_constant,
        constants.elementary_charge,
        constants.electron_mass,
        constants.proton_mass,
        constants.neutron_mass,
        constants.gravitational_constant,
        constants.boltzmann_constant,
        constants.avogadro_constant,
    });
}

fn observe(p: particles.Particle) void {
    std.debug.print(
        \\
        \\========================================
        \\          PARTICLE OBSERVATION
        \\========================================
        \\
        \\Particle:       {s}
        \\Symbol:         {s}
        \\Rest mass:      {} kg
        \\Charge:         {} elementary charges
        \\
    , .{
        p.name,
        p.symbol,
        p.mass_kg,
        p.charge_e,
    });

    if (p.mass_kg == 0.0) {
        std.debug.print(
            \\
            \\Particle classification: Massless boson
            \\Rest mass: zero
            \\Energy: depends on frequency
            \\Momentum: depends on energy
            \\
        , .{});
    } else {
        std.debug.print(
            \\
            \\Particle classification: Massive particle
            \\
        , .{});
    }

    std.debug.print(
        \\
        \\Observation status: THEORETICAL
        \\
    , .{});
}

fn science() void {
    const vector = observations.Vector3{
        .x = 3.0,
        .y = 4.0,
        .z = 0.0,
    };

    std.debug.print(
        \\
        \\========================================
        \\          ORIGIN SCIENCE ENGINE
        \\========================================
        \\
        \\MEASUREMENT SYSTEM
        \\
        \\Length: meters
        \\Mass: kilograms
        \\Time: seconds
        \\Momentum: kg*m/s
        \\Energy: joules
        \\
        \\1000 meters = {} kilometers
        \\
        \\OBSERVATION FRAMEWORK
        \\
        \\Test vector magnitude: {}
        \\
        \\Scientific modules: ONLINE
        \\Particle entries: {d}
        \\
    , .{
        units.metersToKilometers(1000.0),
        observations.positionMagnitude(vector),
        particles.catalogue.len,
    });
}

fn dataset(io: std.Io, gpa: std.mem.Allocator) !void {
    std.debug.print(
        \\
        \\========================================
        \\          DATASET ENGINE
        \\========================================
        \\
        \\Manifests: {s}/   Raw data: {s}/
        \\
        \\  {s:<22} {s:>10}  {s:>9}  {s:>8}  {s}
        \\
    , .{ store.manifests_dir, store.raw_dir, "DATASET", "BYTES", "EVENTS", "ADLER32", "STATUS" });

    var cat = try store.Catalogue.load(io, gpa);
    defer cat.deinit();

    var missing: usize = 0;
    for (cat.entries) |entry| {
        const check = try store.verify(io, gpa, entry);
        switch (check.status) {
            .missing => {
                missing += 1;
                std.debug.print("  {s:<22} {d:>10}  {s:>9}  {x:0>8}  MISSING\n", .{ entry.name, entry.size, "-", entry.adler32 });
            },
            .wrong_size => std.debug.print("  {s:<22} {d:>10}  {s:>9}  {x:0>8}  WRONG SIZE (expected {d})\n", .{ entry.name, check.actual_size, "-", check.actual_adler32, entry.size }),
            .bad_checksum => std.debug.print("  {s:<22} {d:>10}  {s:>9}  {x:0>8}  BAD CHECKSUM (expected {x:0>8})\n", .{ entry.name, check.actual_size, "-", check.actual_adler32, entry.adler32 }),
            .ok => {
                const evs = try store.loadEvents(io, gpa, entry);
                defer gpa.free(evs);
                std.debug.print("  {s:<22} {d:>10}  {d:>9}  {x:0>8}  VERIFIED\n", .{ entry.name, check.actual_size, evs.len, check.actual_adler32 });
            },
        }
    }

    if (missing > 0) {
        std.debug.print("\n{d} dataset(s) missing. Download with: scripts/fetch.sh\n", .{missing});
    }
}

const default_dataset = "Dimuon_DoubleMu";

fn analyze(io: std.Io, gpa: std.mem.Allocator, name: []const u8) !void {
    var cat = try store.Catalogue.load(io, gpa);
    defer cat.deinit();
    const entry = cat.find(name) orelse {
        std.debug.print("\nUnknown dataset: {s}. Run 'origin dataset' to list them.\n", .{name});
        return;
    };

    const evs = try store.loadEvents(io, gpa, entry);
    defer gpa.free(evs);

    // Opposite-charge pairs only: a neutral resonance decays to mu+ mu-.
    var masses: std.ArrayList(f64) = .empty;
    defer masses.deinit(gpa);
    for (evs) |ev| {
        if (ev.oppositeCharge()) try masses.append(gpa, ev.mass());
    }
    std.mem.sort(f64, masses.items, {}, std.sort.asc(f64));

    std.debug.print(
        \\
        \\========================================
        \\          DIMUON MASS ANALYSIS
        \\========================================
        \\
        \\Dataset:            {s} (verified)
        \\Events:             {d}
        \\Opposite-charge:    {d}
        \\Mass range:         {d:.3} - {d:.1} GeV
        \\
        \\SPECTRUM (log scale, # = factor of ~1.25 in events)
        \\
    , .{ entry.name, evs.len, masses.items.len, masses.items[0], masses.items[masses.items.len - 1] });

    var terminal = try spectrum.LogHistogram.init(gpa, 0.5, 200, 40);
    defer terminal.deinit(gpa);
    for (masses.items) |m| terminal.fill(m);
    const scale = 50.0 / @log(@as(f64, @floatFromInt(@max(terminal.max(), 2))) + 1);
    for (terminal.counts, 0..) |count, i| {
        const bar: usize = @intFromFloat(@log(@as(f64, @floatFromInt(count)) + 1) * scale);
        std.debug.print("  {d:>7.2} GeV {d:>6} ", .{ terminal.edge(i), count });
        for (0..bar) |_| std.debug.print("#", .{});
        std.debug.print("\n", .{});
    }

    std.debug.print(
        \\
        \\RESONANCES (measured peak vs PDG 2024)
        \\
        \\  {s:<12} {s:>10} {s:>10} {s:>9} {s:>8} {s:>9}
        \\
    , .{ "PARTICLE", "PDG GeV", "FOUND GeV", "DIFF %", "EVENTS", "PEAK/BKG" });

    var labels: std.ArrayList(spectrum_svg.Label) = .empty;
    defer labels.deinit(gpa);
    for (spectrum.known) |r| {
        // Detector resolution grows with mass; the Z needs a wider window.
        const half_width: f64 = if (r.pdg_mass > 50) 0.04 else 0.015;
        const peak = spectrum.findPeak(masses.items, r.pdg_mass, half_width) orelse continue;
        if (peak.significance_ratio < 1.5) continue;
        std.debug.print("  {s:<12} {d:>10.4} {d:>10.4} {d:>9.3} {d:>8} {d:>9.1}\n", .{
            r.name, r.pdg_mass, peak.mass, 100 * (peak.mass - r.pdg_mass) / r.pdg_mass, peak.events, peak.significance_ratio,
        });
        try labels.append(gpa, .{ .name = r.name, .mass = peak.mass });
    }
    if (labels.items.len == 0) std.debug.print("  none found above background\n", .{});

    // Results: a fine histogram as CSV and SVG.
    var fine = try spectrum.LogHistogram.init(gpa, 0.25, 300, 300);
    defer fine.deinit(gpa);
    for (masses.items) |m| fine.fill(m);

    const stem = entry.name[0 .. std.mem.lastIndexOfScalar(u8, entry.name, '.') orelse entry.name.len];
    try std.Io.Dir.cwd().createDirPath(io, store.results_dir);

    var csv: std.Io.Writer.Allocating = .init(gpa);
    defer csv.deinit();
    try csv.writer.print("mass_lo_gev,mass_hi_gev,events\n", .{});
    for (fine.counts, 0..) |count, i| try csv.writer.print("{d:.5},{d:.5},{d}\n", .{ fine.edge(i), fine.edge(i + 1), count });
    const csv_path = try std.fmt.allocPrint(gpa, "{s}/{s}-mass.csv", .{ store.results_dir, stem });
    defer gpa.free(csv_path);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = csv_path, .data = csv.written() });

    const title = try std.fmt.allocPrint(gpa, "CMS 2011 {s}: DIMUON MASS SPECTRUM ({d} pairs)", .{ stem, masses.items.len });
    defer gpa.free(title);
    const svg = try spectrum_svg.render(gpa, title, fine, labels.items);
    defer gpa.free(svg);
    const svg_path = try std.fmt.allocPrint(gpa, "{s}/{s}-mass.svg", .{ store.results_dir, stem });
    defer gpa.free(svg_path);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = svg_path, .data = svg });

    std.debug.print("\nWrote {s}\nWrote {s}\n", .{ csv_path, svg_path });
}

fn display(io: std.Io, gpa: std.mem.Allocator, name: []const u8, index_arg: ?[]const u8) !void {
    var cat = try store.Catalogue.load(io, gpa);
    defer cat.deinit();
    const entry = cat.find(name) orelse {
        std.debug.print("\nUnknown dataset: {s}. Run 'origin dataset' to list them.\n", .{name});
        return;
    };

    const evs = try store.loadEvents(io, gpa, entry);
    defer gpa.free(evs);

    // Default: the first opposite-charge event near the Z mass, the cleanest
    // picture of a heavy particle decaying to two muons.
    const index: usize = if (index_arg) |text| std.fmt.parseInt(usize, text, 10) catch {
        std.debug.print("\nEvent number must be a non-negative integer, got: {s}\n", .{text});
        return;
    } else for (evs, 0..) |ev, i| {
        if (ev.oppositeCharge() and @abs(ev.mass() - 91.19) < 3) break i;
    } else 0;

    if (index >= evs.len) {
        std.debug.print("\nEvent {d} out of range; {s} has {d} events (0-{d}).\n", .{ index, entry.name, evs.len, evs.len - 1 });
        return;
    }
    const ev = evs[index];

    const stem = entry.name[0 .. std.mem.lastIndexOfScalar(u8, entry.name, '.') orelse entry.name.len];
    const title = try std.fmt.allocPrint(gpa, "ORIGIN EVENT DISPLAY: CMS 2011 {s} #{d}", .{ stem, index });
    defer gpa.free(title);
    const svg = try detector.render(gpa, title, ev);
    defer gpa.free(svg);

    try std.Io.Dir.cwd().createDirPath(io, store.results_dir);
    const path = try std.fmt.allocPrint(gpa, "{s}/event-{s}-{d}.svg", .{ store.results_dir, stem, index });
    defer gpa.free(path);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = svg });

    std.debug.print(
        \\
        \\========================================
        \\          EVENT DISPLAY
        \\========================================
        \\
        \\Dataset:  {s}, event {d} of {d}
        \\Run {d}, event {d}
        \\Muon 1:   charge {d:>2}  pt {d:>7.2} GeV
        \\Muon 2:   charge {d:>2}  pt {d:>7.2} GeV
        \\Mass:     {d:.3} GeV
        \\
        \\Wrote {s}
        \\
    , .{ entry.name, index, evs.len, ev.run, ev.event, ev.mu1.charge, ev.mu1.p.pt(), ev.mu2.charge, ev.mu2.p.pt(), ev.mass(), path });
}

fn projectRow(label: []const u8, v: [3]f64) void {
    const s = projector.split(v);
    std.debug.print("  {s:<26} {d:>7.4} {d:>7.4} {d:>7.4}   {d:>6.3} {d:>6.3} {d:>6.3} {d:>6.3}\n", .{
        label, v[0], v[1], v[2], s.identity, s.q, s.d, s.omega,
    });
}

fn projectHeader(title: []const u8) void {
    std.debug.print("\n{s}\n  {s:<26} {s:>7} {s:>7} {s:>7}   {s:>6} {s:>6} {s:>6} {s:>6}\n", .{ title, "VECTOR", "v1", "v2", "v3", "IDENT", "Q", "D", "OMEGA" });
}

fn projectReport(args: *std.process.Args.Iterator) void {
    std.debug.print(
        \\
        \\========================================
        \\          PROJECTOR ANALYSIS
        \\========================================
        \\
        \\Splits a 3-vector v between two projectors:
        \\  P1 = J/3      identity (the democratic direction 1,1,1)
        \\  P2 = I - J/3  differentiation (the plane orthogonal to it)
        \\IDENT = |P1 v|^2/|v|^2.  Q = 1/(3 IDENT).  D = (Q - 1/3)/(2/3).  OMEGA = 4D(1-D).
        \\D = 0 pure identity, 1 pure differentiation. No assumption that v is a mass.
        \\
    , .{});

    // Custom vector: origin project a b c
    if (args.next()) |first| {
        var v: [3]f64 = undefined;
        v[0] = std.fmt.parseFloat(f64, first) catch return badVector(first);
        for (1..3) |k| {
            const text = args.next() orelse {
                std.debug.print("\nUsage: origin project [a b c]\n", .{});
                return;
            };
            v[k] = std.fmt.parseFloat(f64, text) catch return badVector(text);
        }
        projectHeader("YOUR VECTOR");
        projectRow("input", v);
        return;
    }

    projectHeader("MASS VECTORS v = sqrt(m)  (reproduces Koide; included for comparison)");
    const sq = struct {
        fn of(a: particles.Particle, b: particles.Particle, c: particles.Particle) [3]f64 {
            // Normalise so the components are readable; the split is scale-free.
            const n = @sqrt(a.mass_kg) + @sqrt(b.mass_kg) + @sqrt(c.mass_kg);
            return .{ @sqrt(a.mass_kg) / n, @sqrt(b.mass_kg) / n, @sqrt(c.mass_kg) / n };
        }
    }.of;
    projectRow("charged leptons e,mu,tau", sq(particles.electron, particles.muon, particles.tau));
    projectRow("down quarks d,s,b", sq(particles.down, particles.strange, particles.bottom));
    projectRow("up quarks u,c,t", sq(particles.up, particles.charm, particles.top));

    const u = projector.pmns();
    const v = projector.ckm;
    projectHeader("MIXING VECTORS, NO MASS: |U| neutrino (PMNS), |V| quark (CKM) amplitudes");
    const lepton_rows = [_][]const u8{ "PMNS row e", "PMNS row mu", "PMNS row tau" };
    const nu_cols = [_][]const u8{ "PMNS column nu1", "PMNS column nu2", "PMNS column nu3" };
    const up_rows = [_][]const u8{ "CKM row u", "CKM row c", "CKM row t" };
    const down_cols = [_][]const u8{ "CKM column d", "CKM column s", "CKM column b" };
    var lepton_d: f64 = 0;
    var quark_d: f64 = 0;
    for (0..3) |i| {
        projectRow(lepton_rows[i], projector.row(u, i));
        lepton_d += projector.split(projector.row(u, i)).d;
    }
    for (0..3) |i| {
        projectRow(nu_cols[i], projector.column(u, i));
        lepton_d += projector.split(projector.column(u, i)).d;
    }
    for (0..3) |i| {
        projectRow(up_rows[i], projector.row(v, i));
        quark_d += projector.split(projector.row(v, i)).d;
    }
    for (0..3) |i| {
        projectRow(down_cols[i], projector.column(v, i));
        quark_d += projector.split(projector.column(v, i)).d;
    }
    lepton_d /= 6;
    quark_d /= 6;

    std.debug.print(
        \\
        \\SECTOR SUMMARY (mean D over rows and columns)
        \\  lepton sector (PMNS)  D = {d:.3}
        \\  quark sector (CKM)    D = {d:.3}
        \\
        \\  Each mixing row belongs to one family (PMNS rows: charged leptons,
        \\  columns: neutrinos; CKM rows: up quarks, columns: down quarks), but a
        \\  mixing matrix is shared by its two families, so sector D is the
        \\  cleanest mass-free comparison.
        \\
        \\Sources: CKM PDG 2024 global fit; PMNS from PDG 2024 normal-ordering
        \\angles (sin^2 t12 = 0.307, sin^2 t23 = 0.558, sin^2 t13 = 0.0219, delta = 1.19 pi).
        \\
    , .{ lepton_d, quark_d });
}

/// Mass-free points for each entity, from the mixing matrices.
fn mixingPoints(buf: *[12]projector_svg.Point) [3][]const projector_svg.Point {
    const u = projector.pmns();
    const v = projector.ckm;
    const nu = [_][]const u8{ "nu1", "nu2", "nu3" };
    const lep = [_][]const u8{ "e", "mu", "tau" };
    const up = [_][]const u8{ "u", "c", "t" };
    const down = [_][]const u8{ "d", "s", "b" };
    for (0..3) |i| {
        buf[i] = .{ .label = nu[i], .v = projector.column(u, i), .entity = projector_svg.neutrinos };
        buf[3 + i] = .{ .label = lep[i], .v = projector.row(u, i), .entity = projector_svg.charged_leptons };
        buf[6 + i] = .{ .label = up[i], .v = projector.row(v, i), .entity = projector_svg.quarks };
        buf[9 + i] = .{ .label = down[i], .v = projector.column(v, i), .entity = projector_svg.quarks };
    }
    return .{ buf[0..3], buf[3..6], buf[6..12] };
}

fn writeAndOpen(io: std.Io, gpa: std.mem.Allocator, name: []const u8, svg: []const u8, open_it: bool) !void {
    try std.Io.Dir.cwd().createDirPath(io, store.results_dir);
    const path = try std.fmt.allocPrint(gpa, "{s}/{s}", .{ store.results_dir, name });
    defer gpa.free(path);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = svg });
    std.debug.print("Wrote {s}\n", .{path});
    if (!open_it) return;
    // macOS: show the chart in the default viewer.
    const result = std.process.run(gpa, io, .{ .argv = &.{ "open", path } }) catch {
        std.debug.print("  (could not open it automatically; open the file above)\n", .{});
        return;
    };
    gpa.free(result.stdout);
    gpa.free(result.stderr);
}

fn chart(io: std.Io, gpa: std.mem.Allocator, args: *std.process.Args.Iterator) !void {
    std.debug.print(
        \\
        \\========================================
        \\          CHARTS
        \\========================================
        \\
        \\
    , .{});

    var open_it = true;
    var custom: ?[3]f64 = null;
    var values: [3]f64 = undefined;
    var n: usize = 0;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--no-open")) {
            open_it = false;
            continue;
        }
        if (n == 3) return badVector(arg);
        values[n] = std.fmt.parseFloat(f64, arg) catch return badVector(arg);
        n += 1;
    }
    if (n == 3) custom = values else if (n != 0) {
        std.debug.print("Usage: origin chart [a b c] [--no-open]\n", .{});
        return;
    }

    var buf: [12]projector_svg.Point = undefined;
    const groups = mixingPoints(&buf);

    var points: [13]projector_svg.Point = undefined;
    @memcpy(points[0..12], &buf);
    var count: usize = 12;
    var entities: [4]projector_svg.Entity = .{ projector_svg.neutrinos, projector_svg.charged_leptons, projector_svg.quarks, projector_svg.user };
    var entity_count: usize = 3;
    if (custom) |v| {
        points[12] = .{ .label = "yours", .v = v, .entity = projector_svg.user };
        count = 13;
        entity_count = 4;
        const s = projector.split(v);
        std.debug.print("Your vector ({d}, {d}, {d}): D = {d:.3}, identity share = {d:.3}\n\n", .{ v[0], v[1], v[2], s.d, s.identity });
    }

    const tri = try projector_svg.triangle(gpa, points[0..count], entities[0..entity_count]);
    defer gpa.free(tri);
    try writeAndOpen(io, gpa, "triangle.svg", tri, open_it);

    var rows_buf: [4][]const projector_svg.Point = .{ groups[0], groups[1], groups[2], points[12..13] };
    const rows = rows_buf[0 .. if (custom != null) 4 else 3];
    const ax = try projector_svg.axis(gpa, rows);
    defer gpa.free(ax);
    try writeAndOpen(io, gpa, "axis.svg", ax, open_it);
}

const app_template = @embedFile("app/app.html");

fn writeVectors(w: *std.Io.Writer, name: []const u8, vs: [3][3]f64, last: bool) !void {
    try w.print("\"{s}\":[", .{name});
    for (vs, 0..) |v, i| {
        try w.print("[{d:.6},{d:.6},{d:.6}]{s}", .{ v[0], v[1], v[2], if (i < 2) "," else "" });
    }
    try w.print("]{s}", .{if (last) "" else ","});
}

/// Interactive explorer: the HTML template with ORIGIN's mixing data
/// injected, written to results/ and opened in the browser.
fn app(io: std.Io, gpa: std.mem.Allocator, args: *std.process.Args.Iterator) !void {
    var open_it = true;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--no-open")) open_it = false;
    }
    const u = projector.pmns();
    const v = projector.ckm;
    var cols_u: [3][3]f64 = undefined;
    var cols_v: [3][3]f64 = undefined;
    for (0..3) |i| {
        cols_u[i] = projector.column(u, i);
        cols_v[i] = projector.column(v, i);
    }

    var json: std.Io.Writer.Allocating = .init(gpa);
    defer json.deinit();
    const w = &json.writer;
    try w.print("{{", .{});
    try writeVectors(w, "pmns_rows", u, false);
    try writeVectors(w, "pmns_columns", cols_u, false);
    try writeVectors(w, "ckm_rows", v, false);
    try writeVectors(w, "ckm_columns", cols_v, false);
    try w.print("\"source\":\"Mixing amplitudes |U| (PMNS) and |V| (CKM), PDG 2024, from ORIGIN.\"}}", .{});

    const html = try std.mem.replaceOwned(u8, gpa, app_template, "/*ORIGIN_DATA*/", json.written());
    defer gpa.free(html);

    std.debug.print(
        \\
        \\========================================
        \\          ORIGIN EXPLORER
        \\========================================
        \\
        \\
    , .{});
    try writeAndOpen(io, gpa, "app.html", html, open_it);
}

fn badVector(text: []const u8) void {
    std.debug.print("\nNot a number: {s}. Usage: origin project [a b c]\n", .{text});
}

fn koideFamily(label: []const u8, a: particles.Particle, b: particles.Particle, c: particles.Particle) void {
    const q = koide.ratio(a.mass_kg, b.mass_kg, c.mass_kg);
    const d = koide.organization(q);
    std.debug.print("  {s:<18} {d:>8.5} {d:>8.3} {d:>8.3} {d:>9.3}\n", .{
        label, q, d, koide.equilibrium(d), koide.angleDegrees(a.mass_kg, b.mass_kg, c.mass_kg),
    });
}

fn neutrinoRow(n: [3]f64, lightest: f64) void {
    const q = koide.ratio(n[0], n[1], n[2]);
    const d = koide.organization(q);
    std.debug.print("  {d:<8.3} {d:<9.5} {d:<9.5} {d:<9.5} {d:>8.4} {d:>7.3} {d:>7.3}\n", .{ lightest, n[0], n[1], n[2], q, d, koide.equilibrium(d) });
}

const Triplet = struct {
    names: [3][]const u8,
    sign: [3]f64,
    q: f64,

    fn distance(self: Triplet) f64 {
        return @abs(self.q - 2.0 / 3.0);
    }

    fn closer(_: void, a: Triplet, b: Triplet) bool {
        return a.distance() < b.distance();
    }
};

fn koideReport() void {
    std.debug.print(
        \\
        \\========================================
        \\          KOIDE ANALYSIS
        \\========================================
        \\
        \\Q = (m1+m2+m3) / (sqrt m1 + sqrt m2 + sqrt m3)^2, from 1/3 (equal) to 1.
        \\D = (Q - 1/3) / (2/3)   organizational coordinate, 0 identity .. 1 differentiation
        \\Omega = 4 D (1 - D)     equilibrium, 1 at D = 1/2 (Q = 2/3, a 45 degree angle)
        \\
        \\FERMION FAMILIES (PDG 2024)
        \\
        \\  {s:<18} {s:>8} {s:>8} {s:>8} {s:>9}
        \\
    , .{ "FAMILY", "Q", "D", "OMEGA", "ANGLE" });

    koideFamily("Charged leptons", particles.electron, particles.muon, particles.tau);
    koideFamily("Down-type quarks", particles.down, particles.strange, particles.bottom);
    koideFamily("Up-type quarks", particles.up, particles.charm, particles.top);

    // Quarks are confined, so also treat them as one bound entity: merge
    // each generation's up and down partner (u+d, c+s, t+b).
    const g1 = particles.up.mass_kg + particles.down.mass_kg;
    const g2 = particles.charm.mass_kg + particles.strange.mass_kg;
    const g3 = particles.top.mass_kg + particles.bottom.mass_kg;
    const qq = koide.ratio(g1, g2, g3);
    const dq = koide.organization(qq);
    std.debug.print("  {s:<18} {d:>8.5} {d:>8.3} {d:>8.3} {d:>9.3}   (u+d, c+s, t+b)\n", .{
        "Quarks, bound", qq, dq, koide.equilibrium(dq), koide.angleDegrees(g1, g2, g3),
    });

    std.debug.print(
        \\
        \\NEUTRINOS: absolute masses unknown, so Q depends on the lightest mass.
        \\NuFIT 6.0 splittings: dm21^2 = {e:.3} eV^2, |dm31^2| = {e:.3} eV^2
        \\
        \\Normal ordering (m1 lightest)
        \\  {s:<8} {s:<9} {s:<9} {s:<9} {s:>8} {s:>7} {s:>7}
        \\
    , .{ koide.nu_dm21_sq, koide.nu_dm31_sq, "m1 eV", "m1", "m2", "m3", "Q", "D", "OMEGA" });
    const scan = [_]f64{ 0.0, 0.001, 0.003, 0.01, 0.03, 0.1 };
    for (scan) |m| neutrinoRow(koide.neutrinoMasses(m), m);
    std.debug.print("\nInverted ordering (m3 lightest)\n  {s:<8} {s:<9} {s:<9} {s:<9} {s:>8} {s:>7} {s:>7}\n", .{ "m3 eV", "m1", "m2", "m3", "Q", "D", "OMEGA" });
    for (scan) |m| neutrinoRow(koide.neutrinoMassesInverted(m), m);
    std.debug.print(
        \\
        \\  Neutrino Q is at most 0.585 (normal) or 0.500 (inverted) and falls toward
        \\  1/3 as the lightest mass grows. Its place on the D axis is not yet measured.
        \\
    , .{});

    // Every triplet of the nine charged fermions, with all-positive roots or
    // one negative root (the signed-root extension).
    const fermions = [_]particles.Particle{
        particles.electron, particles.muon,    particles.tau,
        particles.up,       particles.charm,   particles.top,
        particles.down,     particles.strange, particles.bottom,
    };
    var triplets: [84 * 4]Triplet = undefined;
    var n: usize = 0;
    for (0..fermions.len) |i| for (i + 1..fermions.len) |j| for (j + 1..fermions.len) |k| {
        const m = [3]f64{ fermions[i].mass_kg, fermions[j].mass_kg, fermions[k].mass_kg };
        const signs = [_][3]f64{ .{ 1, 1, 1 }, .{ -1, 1, 1 }, .{ 1, -1, 1 }, .{ 1, 1, -1 } };
        for (signs) |sign| {
            triplets[n] = .{ .names = .{ fermions[i].symbol, fermions[j].symbol, fermions[k].symbol }, .sign = sign, .q = koide.signedRatio(m, sign) };
            n += 1;
        }
    };
    std.mem.sort(Triplet, &triplets, {}, Triplet.closer);

    var near: usize = 0;
    for (triplets) |t| {
        if (t.distance() < 0.01) near += 1;
    }

    std.debug.print(
        \\
        \\TRIPLETS CLOSEST TO Q = 2/3 ({d} triplets of 9 charged fermions, a minus sign marks a negative root)
        \\
        \\  {s:<20} {s:>9} {s:>10} {s:>7}
        \\
    , .{ triplets.len, "TRIPLET", "Q", "Q - 2/3", "D" });
    for (triplets[0..12]) |t| {
        var label_buf: [40]u8 = undefined;
        const label = std.fmt.bufPrint(&label_buf, "{s}{s} {s}{s} {s}{s}", .{
            if (t.sign[0] < 0) "-" else "", t.names[0],
            if (t.sign[1] < 0) "-" else "", t.names[1],
            if (t.sign[2] < 0) "-" else "", t.names[2],
        }) catch "?";
        std.debug.print("  {s:<20} {d:>9.5} {e:>10.2} {d:>7.3}\n", .{ label, t.q, t.q - 2.0 / 3.0, koide.organization(t.q) });
    }

    std.debug.print(
        \\
        \\  {d} of {d} triplets fall within 0.01 of 2/3, so near-2/3 values occur by chance.
        \\  The charged leptons stand out by precision ({e:.1} from 2/3), not by being near it.
        \\
        \\NOTE: quark masses are scheme-dependent (MS-bar vs pole); treat quark Q as indicative.
        \\
    , .{ near, triplets.len, @abs(koide.ratio(particles.electron.mass_kg, particles.muon.mass_kg, particles.tau.mass_kg) - 2.0 / 3.0) });
}

fn fail(err: anyerror) void {
    switch (err) {
        error.FileNotFound => std.debug.print("\nError: file not found. Run origin from the origin/ project folder.\n", .{}),
        error.DatasetMissing => std.debug.print("\nError: dataset not downloaded. Run scripts/fetch.sh\n", .{}),
        error.DatasetCorrupt => std.debug.print("\nError: dataset failed verification. Delete it from data/raw/ and re-run scripts/fetch.sh\n", .{}),
        else => std.debug.print("\nError: {s}\n", .{@errorName(err)}),
    }
}

pub fn main(init: std.process.Init) void {
    var args = init.minimal.args.iterate();
    _ = args.skip();

    header();

    const command = args.next() orelse {
        help();
        return;
    };

    if (std.mem.eql(u8, command, "help")) {
        help();
    } else if (std.mem.eql(u8, command, "info")) {
        info();
    } else if (std.mem.eql(u8, command, "science")) {
        science();
    } else if (std.mem.eql(u8, command, "catalogue")) {
        catalogue();
    } else if (std.mem.eql(u8, command, "constants")) {
        printConstants();
    } else if (std.mem.eql(u8, command, "dataset")) {
        dataset(init.io, init.gpa) catch |err| fail(err);
    } else if (std.mem.eql(u8, command, "analyze")) {
        analyze(init.io, init.gpa, args.next() orelse default_dataset) catch |err| fail(err);
    } else if (std.mem.eql(u8, command, "observe")) {
        const name = args.next() orelse {
            std.debug.print("Usage: origin observe <particle>\n", .{});
            return;
        };

        if (particles.find(name)) |p| {
            observe(p);
        } else {
            std.debug.print("Unknown particle: {s}\n", .{name});
        }
    } else if (std.mem.eql(u8, command, "display")) {
        display(init.io, init.gpa, args.next() orelse "Zmumu", args.next()) catch |err| fail(err);
    } else if (std.mem.eql(u8, command, "app")) {
        app(init.io, init.gpa, &args) catch |err| fail(err);
    } else if (std.mem.eql(u8, command, "chart")) {
        chart(init.io, init.gpa, &args) catch |err| fail(err);
    } else if (std.mem.eql(u8, command, "project")) {
        projectReport(&args);
    } else if (std.mem.eql(u8, command, "koide")) {
        koideReport();
    } else {
        std.debug.print("Unknown command: {s}\n", .{command});
        help();
    }
}
