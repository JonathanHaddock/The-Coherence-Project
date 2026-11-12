const std = @import("std");
const detector = @import("visualization/detector.zig");

const constants = @import("science/constants.zig");
const units = @import("science/units.zig");
const particles = @import("science/particles.zig");
const observations = @import("science/observations.zig");
const koide = @import("analysis/koide.zig");
const projector = @import("analysis/projector.zig");
const weak = @import("analysis/weak.zig");
const charge = @import("analysis/charge.zig");
const majorana = @import("analysis/majorana.zig");
const selection = @import("analysis/selection.zig");
const universality = @import("analysis/universality.zig");
const generations = @import("analysis/generations.zig");
const export_ = @import("dataset/export.zig");
const weak_svg = @import("visualization/weak_svg.zig");
const kinematics = @import("analysis/kinematics.zig");
const manifest = @import("dataset/manifest.zig");
const events = @import("dataset/events.zig");
const store = @import("dataset/store.zig");
const spectrum = @import("analysis/spectrum.zig");
const spectrum_svg = @import("visualization/spectrum_svg.zig");
const projector_svg = @import("visualization/projector_svg.zig");
const engine = @import("engine/pixel.zig");
const clocks = @import("engine/clocks.zig");
const grid3 = @import("engine/grid3.zig");
const lepton = @import("engine/lepton.zig");
const record = @import("engine/record.zig");

test {
    _ = koide;
    _ = projector;
    _ = weak;
    _ = charge;
    _ = majorana;
    _ = selection;
    _ = universality;
    _ = generations;
    _ = export_;
    _ = weak_svg;
    _ = kinematics;
    _ = manifest;
    _ = events;
    _ = store;
    _ = spectrum;
    _ = detector;
    _ = projector_svg;
    _ = engine;
    _ = clocks;
    _ = grid3;
    _ = lepton;
    _ = record;
    _ = @import("visualization/labels.zig");
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
        \\  origin weak [--no-open]
        \\  origin charge
        \\  origin majorana
        \\  origin export
        \\  origin universality
        \\  origin generations
        \\  origin display [dataset] [event]
        \\  origin engine [ticks] [seed]
        \\  origin clocks [seed]
        \\  origin lattice3 [display] [update] [core] [ticks] [gravity]
        \\  origin lepton [core] [ticks] [v1|signed|turing]
        \\  origin structure [--no-open]
        \\  origin record mode=lattice|v1|signed|turing|control core=.. p=.. ticks=.. every=.. [display=.. update=.. gravity=on seed=..]
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
const structure_template = @embedFile("app/structure.html");

/// Model page: the charged-lepton family in the mass view (Koide) and the
/// coupling view (1/3 split), plus where each holds in energy.
fn structurePage(io: std.Io, gpa: std.mem.Allocator, args: *std.process.Args.Iterator) !void {
    var open_it = true;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--no-open")) open_it = false;
    }
    const g = generations;
    const rule = weak.solve(1.0 / 3.0);
    const mz = weak.measured[0];
    // E158 Moller scattering, MS-bar at Q^2 = 0.026 GeV^2 (Q = 0.161 GeV):
    // 0.2381 +- 0.0015 (stat) +- 0.0014 (syst), Mastromarino, Caltech thesis 2004.
    const e158_v: f64 = 0.2381;
    const e158_e: f64 = @sqrt(0.0015 * 0.0015 + 0.0014 * 0.0014);
    const q_e158: f64 = @sqrt(0.026);
    var j: std.Io.Writer.Allocating = .init(gpa);
    defer j.deinit();
    try j.writer.print(
        \\{{"m_e":{d},"m_mu":{d},"m_tau":{d},"rule_s":{d:.6},"pull_z":{d:.3},"pull_e158":{d:.3},
        \\"running":[[0.0003,0.2387],[{d:.4},0.2387],[91.1876,{d}],[172.5,0.23462]],
        \\"points":[{{"q":{d:.4},"v":{d},"err":{d:.5},"label":"E158 (e⁻e⁻), MS-bar","ok":false,"left":true}},
        \\{{"q":91.1876,"v":{d},"err":{d},"label":"Z mass, PDG 2025","ok":true,"left":true}},
        \\{{"q":172.5,"v":0.23462,"err":0.00012,"label":"top mass (SM calc.)","ok":false,"left":false}}]}}
    , .{ g.m_e, g.m_mu, g.tau_measurements[0].value, rule, (rule - mz.value) / mz.err, (rule - e158_v) / e158_e, q_e158, mz.value, q_e158, e158_v, e158_e, mz.value, mz.err });
    const html = try std.mem.replaceOwned(u8, gpa, structure_template, "/*DATA*/{}", j.written());
    defer gpa.free(html);
    try writeAndOpen(io, gpa, "structure.html", html, open_it);
}

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

fn generationsReport() void {
    const g = generations;
    std.debug.print(
        \\
        \\========================================
        \\          MASS WITHIN AN ENTITY
        \\========================================
        \\
        \\sqrt(m_k) = mu (1 + A cos(delta + 2 pi k/3))
        \\  mu    identity scale (the (1,1,1) part)
        \\  A     how differentiated the copies are (A = sqrt 2 is Koide's Q = 2/3)
        \\  delta direction of differentiation
        \\
        \\  {s:<20} {s:>10} {s:>9} {s:>9} {s:>9}
        \\
    , .{ "ENTITY", "mu (MeV^.5)", "A", "delta", "Q" });
    const lep = g.fit(1776.93, g.m_e, g.m_mu);
    const fermions = [_]struct { name: []const u8, p: g.Params }{
        .{ .name = "charged leptons", .p = lep },
        .{ .name = "down quarks", .p = g.fit(particles.bottom.mass_kg / particles.mev_to_kg, particles.down.mass_kg / particles.mev_to_kg, particles.strange.mass_kg / particles.mev_to_kg) },
        .{ .name = "up quarks", .p = g.fit(particles.top.mass_kg / particles.mev_to_kg, particles.up.mass_kg / particles.mev_to_kg, particles.charm.mass_kg / particles.mev_to_kg) },
    };
    for (fermions) |f| {
        std.debug.print("  {s:<20} {d:>10.4} {d:>9.5} {d:>9.5} {d:>9.5}\n", .{ f.name, f.p.mu, f.p.a, f.p.delta, f.p.q });
    }
    std.debug.print("  (quark masses are scheme-dependent; quark rows are indicative)\n", .{});

    const t = g.koideTau(g.m_e, g.m_mu);
    std.debug.print(
        \\
        \\TAU MASS: Koide's prediction from the electron and muon alone
        \\  prediction (Q = 2/3 exactly)       {d:.4} MeV
        \\
        \\  {s:<20} {s:>12} {s:>9} {s:>9}
        \\
    , .{ t, "MEASUREMENT", "MeV", "ERROR", "PULL" });
    for (g.tau_measurements) |m| {
        std.debug.print("  {s:<20} {d:>12.3} {d:>9.3} {d:>8.2}s\n", .{ m.name, m.value, m.err, (m.value - t) / m.err });
    }

    // delta and its uncertainty from the tau mass (electron, muon errors negligible).
    const lo = g.fit(1776.93 - 0.09, g.m_e, g.m_mu).delta;
    const hi = g.fit(1776.93 + 0.09, g.m_e, g.m_mu).delta;
    const d_err = @abs(hi - lo) / 2;
    const r = g.ratiosFrom(2.0 / 9.0);
    std.debug.print(
        \\
        \\DIRECTION: Brannen's delta = 2/9 for charged leptons
        \\  measured delta = {d:.7} +- {d:.7}    2/9 = {d:.7}    pull {d:.2}s
        \\  With A = sqrt 2 and delta = 2/9 exactly, mass ratios are fixed:
        \\    m_mu / m_e  predicted {d:.3}   measured {d:.3}
        \\    m_tau / m_e predicted {d:.2}  measured {d:.2}
        \\
        \\  Caveat: 2/9 was noticed after the fact, among many simple fractions.
        \\
    , .{ lep.delta, d_err, 2.0 / 9.0, (lep.delta - 2.0 / 9.0) / d_err, r.mu_over_e, g.m_mu / g.m_e, r.tau_over_e, 1776.93 / g.m_e });
}

fn universalityReport() void {
    const r = universality.cmsRatio();
    std.debug.print(
        \\
        \\========================================
        \\          LEPTON UNIVERSALITY
        \\========================================
        \\
        \\Are electrons, muons and taus identical by force? Three tests:
        \\
        \\1. ORIGIN, CMS open data (peak position only)
        \\   Z peak: electrons 90.799 +- 0.080 GeV, muons 90.817 +- 0.037 GeV
        \\   difference -0.019 +- 0.088 GeV (0.2 sigma, statistical)
        \\   Event counts cannot be compared: the outreach files are subsets
        \\   capped at fixed event counts, with no published efficiencies.
        \\
        \\2. CMS, efficiency-corrected (arXiv:1107.4789, 2010 data, 36 pb^-1)
        \\   sigma x B(Z -> ee)     = {d:.3} +- {d:.3} (stat) +- {d:.3} (syst) nb
        \\   sigma x B(Z -> mumu)   = {d:.3} +- {d:.3} (stat) +- {d:.3} (syst) nb
        \\   acceptance: ee {d:.4}, mumu {d:.4};  ee selection efficiency {d:.1}%
        \\   ratio ee / mumu        = {d:.3} +- {d:.3} (exp)  +- {d:.3} (incl. theory)
        \\   (luminosity cancels; theory treated as uncorrelated, conservative)
        \\
        \\3. LEP, Z partial widths (PDG), the precision test
        \\   Gamma(ee)     = {d:.2} +- {d:.2} MeV
        \\   Gamma(mumu)   = {d:.2} +- {d:.2} MeV
        \\   Gamma(tautau) = {d:.2} +- {d:.2} MeV
        \\   Gamma(mumu) / Gamma(ee) = {d:.4} +- {d:.4}
        \\
        \\All three agree: the Z couples to electrons, muons and taus equally,
        \\to 0.3% at LEP. Identical by force, as the framework says.
        \\
    , .{
        universality.cms_ee.value,    universality.cms_ee.stat,    universality.cms_ee.syst,
        universality.cms_mumu.value,  universality.cms_mumu.stat,  universality.cms_mumu.syst,
        universality.cms_acceptance_ee, universality.cms_acceptance_mumu, universality.cms_efficiency_ee * 100,
        r.value, r.err_no_theory, r.err_all,
        universality.lep_ee[0], universality.lep_ee[1],
        universality.lep_mumu[0], universality.lep_mumu[1],
        universality.lep_tautau[0], universality.lep_tautau[1],
        universality.lep_mumu_over_ee[0], universality.lep_mumu_over_ee[1],
    });
}

fn majoranaReport() void {
    std.debug.print(
        \\
        \\========================================
        \\          MAJORANA TEST
        \\========================================
        \\
        \\Framework: neutrinos are a pole carrying no charge of any kind, so
        \\they are their own antiparticles (Majorana). Majorana neutrinos also
        \\force charge quantization (eps = 0, target 1; Babu-Mohapatra 1989).
        \\
        \\Signal: neutrinoless double-beta decay, at a rate set by the effective
        \\Majorana mass m_bb. Its range, scanning the two unknown phases:
        \\
        \\  {s:>10}   {s:>22}   {s:>22}
        \\
    , .{ "lightest", "normal ordering (meV)", "inverted ordering (meV)" });
    for ([_]f64{ 0, 0.001, 0.003, 0.005, 0.01, 0.03, 0.1 }) |l| {
        const n = majorana.band(l, .normal);
        const i = majorana.band(l, .inverted);
        std.debug.print("  {d:>7.3} eV   {d:>9.2} to {d:>9.2}   {d:>9.2} to {d:>9.2}\n", .{ l, n.min * 1e3, n.max * 1e3, i.min * 1e3, i.max * 1e3 });
    }
    std.debug.print("\nEXPERIMENTS (reach in m_bb; range = nuclear-model uncertainty)\n", .{});
    for (majorana.experiments) |e| {
        std.debug.print("  {s:<26} {d:>6.1} to {d:>6.1} meV   {s}\n", .{ e.name, e.lo * 1e3, e.hi * 1e3, e.status });
    }
    const io = majorana.band(0, .inverted);
    std.debug.print(
        \\
        \\  Inverted ordering never drops below {d:.1} meV: within reach of
        \\  LEGEND-1000 and nEXO for most nuclear models, just out of reach for the
        \\  most pessimistic ones (24 and 20.3 meV). Normal ordering can cancel to
        \\  zero for a lightest mass of a few meV, beyond any planned experiment.
        \\
        \\  A signal would confirm the framework's Majorana neutrinos (and eps = 0).
        \\  No signal refutes it only if the inverted ordering is established;
        \\  in normal ordering, Majorana neutrinos can still hide.
        \\
    , .{io.min * 1e3});
}

fn chargeReport() void {
    std.debug.print(
        \\
        \\========================================
        \\          NEUTRINO CHARGE TEST
        \\========================================
        \\
        \\With right-handed neutrinos, anomaly cancellation leaves one free
        \\shift of all electric charges along B - L:  Q = Q_SM + eps (B - L).
        \\
        \\  Standard Model + right-handed neutrinos:  eps free (must be measured)
        \\  Selection framework:                       eps = 0 exactly
        \\     (neutrinos select only the weak force, so carry no charge)
        \\
        \\CHARGES AS A FUNCTION OF eps (checked by ORIGIN's tests)
        \\  neutrino         -eps
        \\  electron         -1 - eps
        \\  up quark         2/3 + eps/3
        \\  down quark      -1/3 + eps/3
        \\  proton           1 + eps
        \\  neutron          eps
        \\  hydrogen atom    0 for every eps
        \\  one generation   0 for every eps
        \\
        \\MEASUREMENTS CONVERTED TO eps (units of e)
        \\
        \\  {s:<34} {s:>12} {s:>11} {s:>8}
        \\
    , .{ "MEASUREMENT", "eps", "1 sigma", "PULL"});
    for (charge.bounds) |b| {
        if (!b.constrains) {
            std.debug.print("  {s:<34} {s:>12} {s:>11} {s:>8}\n", .{ b.name, "no limit", "-", "-" });
            continue;
        }
        std.debug.print("  {s:<34} {e:>12.2} {e:>11.2} {d:>7.2}s\n", .{ b.name, b.central, b.err, (b.central - 0) / b.err });
    }
    std.debug.print("\nSources:\n", .{});
    for (charge.bounds) |b| std.debug.print("  {s}: {s}\n", .{ b.name, b.source });
    std.debug.print(
        \\
        \\The framework's eps = 0 is consistent with every measurement. The best
        \\test is the neutron's charge: |eps| below about 2e-21 e (2 sigma).
        \\Matter neutrality (hydrogen) cannot test this shift at all.
        \\Limitation: the minimal Standard Model (no right-handed neutrinos)
        \\already forces eps = 0, so this separates the framework only from
        \\the extended Standard Model.
        \\
    , .{});
}

fn weakReport(io: std.Io, gpa: std.mem.Allocator, args: *std.process.Args.Iterator) !void {
    var open_it = true;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--no-open")) open_it = false;
    }
    const sol = weak.solve(1.0 / 3.0);
    std.debug.print(
        \\
        \\========================================
        \\          WEAK MIXING ANGLE TEST
        \\========================================
        \\
        \\Charged-lepton interaction vector (EM, weak) depends on one free
        \\Standard Model parameter, s = sin^2(theta_W):
        \\  weak / EM = (1/4 - s + 2 s^2) / (s (1 - s))
        \\
        \\Rule tested: charged leptons carry 2/3 on their dominant axis and
        \\1/3 projected (mirroring Koide's 2/3).
        \\
        \\  Rule fixes sin^2(theta_W) = {d:.6}
        \\
        \\  {s:<28} {s:>9} {s:>9} {s:>9}
        \\
    , .{ sol, "MEASURED DEFINITION", "VALUE", "ERROR", "PULL" });
    for (weak.measured) |m| {
        std.debug.print("  {s:<28} {d:>9.5} {d:>9.5} {d:>8.1}s\n", .{ m.name, m.value, m.err, (sol - m.value) / m.err });
    }
    std.debug.print(
        \\
        \\  Pull = (rule - measured) / error. Within about 2 sigma is consistent.
        \\  The rule matches only the MS-bar definition at the Z mass, and the
        \\  angle changes with energy, so it holds at one scale only. Treat as a
        \\  candidate, chosen after seeing the data.
        \\
        \\
    , .{});
    const svg = try weak_svg.render(gpa);
    defer gpa.free(svg);
    try writeAndOpen(io, gpa, "weak-angle.svg", svg, open_it);
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

var engine_grid: engine.Grid = undefined;

fn engineReport(args: anytype) void {
    const ticks = std.fmt.parseInt(i64, args.next() orelse "2000", 10) catch 2000;
    const seed = std.fmt.parseInt(u64, args.next() orelse "20261110", 10) catch 20261110;

    std.debug.print("\n--- STEP 1: one pixel, one beta decay ---\n", .{});
    for ([_]u3{ 0b001, 0b010, 0b100 }) |pat| {
        var p = engine.Pixel{ .pattern = pat };
        const e = engine.betaDecay(&p).?;
        std.debug.print(
            "  {b:0>3} -> {b:0>3}  quark flash (cell {d})  q: {d}/3 -> {d}/3 + e {d}/3 + nu {d}/3  {s}\n",
            .{ e.before, e.after, e.flipped_cell, e.quark_q[0], e.quark_q[1], e.electron_q, e.neutrino_q, if (e.balanced()) "BALANCED" else "FAIL" },
        );
    }

    std.debug.print("\n--- STEP 2: two pixels, flash rule ---\n", .{});
    var a = engine.Pixel{ .pattern = 0b101 };
    var b = engine.Pixel{ .pattern = 0b011 };
    var t: i64 = 0;
    while (t < 6) : (t += 1) {
        const src = if (@mod(t, 2) == 0) &a else &b;
        const dst = if (@mod(t, 2) == 0) &b else &a;
        dst.receive(src.pattern);
        std.debug.print("  t={d} {s} shows {b:0>3} -> {s} reinforce {any} conserved {any}", .{ t, if (src == &a) "A" else "B", src.pattern, if (dst == &a) "A" else "B", dst.reinforce, dst.conserved });
        if (dst.ready()) {
            const nu = dst.flash(t);
            std.debug.print("  FLASH -> {b:0>3}, neutrino carries {d}", .{ dst.pattern, nu });
        }
        std.debug.print("\n", .{});
    }

    std.debug.print("\n--- STEP 3: {d}x{d} torus, {d} ticks, seed {d} ---\n", .{ engine.side, engine.side, ticks, seed });
    engine_grid = engine.Grid.init(seed);
    std.debug.print("  tick   flashes  neutrino  agreement\n", .{});
    var total: u64 = 0;
    var last_active: i64 = -1;
    t = 0;
    while (t < ticks) : (t += 1) {
        const st = engine_grid.tick(t, if (t == 0) @as(?usize, engine.n / 2) else null);
        total += st.flashes;
        if (st.flashes > 0) last_active = t;
        if (t < 10 or @mod(t, @max(1, @divTrunc(ticks, 20))) == 0)
            std.debug.print("  {d:>5}  {d:>7}  {d:>8}  {d:.4}\n", .{ @as(u64, @intCast(t)), st.flashes, st.neutrino, st.agreement });
    }
    std.debug.print("  total flashes {d}; last active tick {d}\n", .{ total, last_active });

    std.debug.print("\n  Constant-hazard test (section 5): h(k) = P(flash at gap k | no flash before k)\n", .{});
    var remaining: u64 = 0;
    for (engine_grid.intervals) |c| remaining += c;
    if (remaining == 0) {
        std.debug.print("  no repeat flashes: nothing to test\n", .{});
        return;
    }
    var k: usize = 1;
    while (k < 16) : (k += 1) {
        const c = engine_grid.intervals[k];
        if (remaining == 0) break;
        std.debug.print("  gap {d:>2}: {d:>8}  h = {d:.3}\n", .{ k, c, @as(f64, @floatFromInt(c)) / @as(f64, @floatFromInt(remaining)) });
        remaining -= c;
    }
}

fn fmtR(r: ?f64, buf: []u8) []const u8 {
    if (r) |v| return std.fmt.bufPrint(buf, "{d:>6.2}", .{v}) catch "?";
    return "   n/a";
}

fn clocksReport(args: anytype) void {
    const seed = std.fmt.parseInt(u64, args.next() orelse "20261110", 10) catch 20261110;
    std.debug.print(
        \\
        \\--- REGION CLOCKS (section 11) ---
        \\{d} regions of {d}x{d}. Per window: mean coherence, mean flashes per region per tick
        \\(raw, and merged = coherent co-flashing group counts as one tick), and the
        \\correlation r across regions between coherence and clock rate.
        \\Section 11 predicts r < 0 (coherent regions run slow). seed {d}
        \\
        \\
    , .{ clocks.regions, clocks.block, clocks.block, seed });
    const windows = [_][2]i64{ .{ 0, 25 }, .{ 25, 100 }, .{ 100, 400 } };
    for ([_]engine.Start{ .random, .{ .core = 20 } }) |start| {
        for ([_]engine.Update{ .sync, .sweep }) |upd| {
            for ([_]engine.Display{ .fill_empty, .hold, .one_cell, .flip_all }) |disp| {
                engine_grid = engine.Grid.initWith(.{ .display = disp, .update = upd, .start = start, .seed = seed });
                std.debug.print("{s:<6} {s:<5} {s:<10}", .{ if (start == .random) "random" else "core20", @tagName(upd), @tagName(disp) });
                var t: i64 = 0;
                for (windows) |win| {
                    var w: clocks.Window = .{};
                    while (t < win[1]) : (t += 1) {
                        _ = engine_grid.tick(t, if (t == 0) @as(?usize, engine.n / 2) else null);
                        w.record(&engine_grid);
                    }
                    const s = clocks.summarize(&w);
                    var b1: [16]u8 = undefined;
                    var b2: [16]u8 = undefined;
                    std.debug.print(" | t{d}-{d}: coh {d:.2} raw {d:>5.1} mrg {d:>5.1} r {s}/{s}", .{ win[0], win[1], s.mean_coherence, s.mean_raw, s.mean_merged, fmtR(s.r_raw, &b1), fmtR(s.r_merged, &b2) });
                }
                std.debug.print("\n", .{});
            }
        }
    }
    std.debug.print("\n  r shown as raw/merged. n/a = no spread (all regions identical or silent).\n", .{});
}

var lattice: grid3.Grid3 = undefined;

fn lattice3Report(args: anytype) void {
    const disp = std.meta.stringToEnum(engine.Display, args.next() orelse "hold") orelse .hold;
    const upd = std.meta.stringToEnum(engine.Update, args.next() orelse "sync") orelse .sync;
    const core = std.fmt.parseInt(u32, args.next() orelse "8", 10) catch 8;
    const ticks = std.fmt.parseInt(i64, args.next() orelse "1500", 10) catch 1500;
    const gravity = std.mem.eql(u8, args.next() orelse "off", "gravity");
    const from = @divTrunc(ticks * 2, 3);
    std.debug.print(
        \\
        \\--- 3D LATTICE {d}^3, 6 neighbors ---
        \\display {s}, update {s}, core sphere radius {d}, {d} ticks, averages over ticks {d}-{d}
        \\carrier: released neutrino units, one hop per tick, lost at box edge, feedback {s}
        \\
        \\  dist   pixels  flash rate  agreement  carrier      carrier*dist
        \\
    , .{ grid3.side, @tagName(disp), @tagName(upd), core, ticks, from, ticks, if (gravity) "ON (rule 6: 3 units -> +1 reinforce per cell)" else "off" });
    lattice.init(.{ .display = disp, .update = upd, .start = if (core == 0) .random else .{ .core = core } });
    lattice.gravity = gravity;
    const bins = grid3.side / 2;
    var rate: [bins]f64 = @splat(0);
    var car: [bins]f64 = @splat(0);
    var cnt: [bins]f64 = @splat(0);
    var agr: [bins]f64 = @splat(0);
    for (0..grid3.n) |i| {
        const b: usize = @intFromFloat(@floor(grid3.radius(i)));
        if (b < bins) cnt[b] += 1;
    }
    var t: i64 = 0;
    var total: u64 = 0;
    while (t < ticks) : (t += 1) {
        total += lattice.tick(t, if (t == 0) @as(?usize, grid3.index(grid3.side / 2, grid3.side / 2, grid3.side / 2)) else null);
        if (t < from) continue;
        for (0..grid3.n) |i| {
            const b: usize = @intFromFloat(@floor(grid3.radius(i)));
            if (b >= bins) continue;
            if (lattice.fired[i]) rate[b] += 1;
            car[b] += lattice.carrier[i];
            agr[b] += lattice.agreement(i);
        }
    }
    const w: f64 = @floatFromInt(ticks - from);
    // log-log slope of carrier vs distance, outside the core and away from the edge
    var sx: f64 = 0;
    var sy: f64 = 0;
    var sxx: f64 = 0;
    var sxy: f64 = 0;
    var k: f64 = 0;
    for (1..bins) |b| {
        const r = rate[b] / (cnt[b] * w);
        const c = car[b] / (cnt[b] * w);
        const d: f64 = @as(f64, @floatFromInt(b)) + 0.5;
        std.debug.print("  {d:>4}  {d:>7}  {d:>10.3}  {d:>9.3}  {e:>11.3}  {e:>11.3}\n", .{ b, @as(u64, @intFromFloat(cnt[b])), r, agr[b] / (cnt[b] * w), c, c * d });
        if (b > core + 2 and b < bins - 4 and c > 0) {
            sx += @log(d);
            sy += @log(c);
            sxx += @log(d) * @log(d);
            sxy += @log(d) * @log(c);
            k += 1;
        }
    }
    std.debug.print("  total flashes {d}\n", .{total});
    if (k > 2) {
        const slope = (k * sxy - sx * sy) / (k * sxx - sx * sx);
        std.debug.print("  carrier falloff exponent outside core: {d:.2}  (1/distance = -1.00)\n", .{slope});
    }
}

var lep_grid: lepton.Lepton = undefined;

fn leptonReport(args: anytype) void {
    const core = std.fmt.parseInt(u32, args.next() orelse "0", 10) catch 0;
    const ticks = std.fmt.parseInt(i64, args.next() orelse "1500", 10) catch 1500;
    const mode_s = args.next() orelse "v1";
    const signed = std.mem.eql(u8, mode_s, "signed");
    const turing = std.mem.eql(u8, mode_s, "turing");
    std.debug.print(
        \\
        \\--- LEPTON MODE {s} 48^3 (rule choices 7-9) ---
        \\cells = e, mu, tau. Carrier: 3 channels, wrapped edges, absorbed per whole unit as the flash rule.
        \\core {d}, {d} ticks, display one_cell, sync
        \\
        \\  tick  flashing   agree   carrier     memory    e      mu     tau   (fraction filled)
        \\
    , .{ if (turing) "turing (rule 11)" else if (signed) "signed (rule 10)" else "v1 (rule 9)", core, ticks });
    lep_grid.init(20261110, core);
    lep_grid.signed = signed;
    lep_grid.turing = turing;
    const c = grid3.index(grid3.side / 2, grid3.side / 2, grid3.side / 2);
    var t: i64 = 0;
    const bins = grid3.side / 2;
    var rate: [bins]f64 = @splat(0);
    var agr: [bins]f64 = @splat(0);
    var cnt: [bins]f64 = @splat(0);
    var w: f64 = 0;
    while (t < ticks) : (t += 1) {
        const f = lep_grid.tick(t, if (t == 0) c else null);
        const every = @max(1, @divTrunc(ticks, 15));
        if (@mod(t, every) == 0 or t == ticks - 1) {
            var a: f64 = 0;
            var mem: u64 = 0;
            var gen: [3]f64 = .{ 0, 0, 0 };
            for (0..lepton.n) |i| {
                a += lep_grid.agreement(i);
                mem += lep_grid.px[i].memoryTotal();
                for (0..3) |k| {
                    if (lep_grid.px[i].pattern & (@as(u3, 1) << @intCast(k)) != 0) gen[k] += 1;
                }
            }
            const nf: f64 = lepton.n;
            std.debug.print("  {d:>5}  {d:>7.4}  {d:>6.4}  {e:>9.3}  {d:>9}  {d:.3}  {d:.3}  {d:.3}\n", .{ t, @as(f64, @floatFromInt(f)) / nf, a / nf, lep_grid.carrierTotal(), mem, gen[0] / nf, gen[1] / nf, gen[2] / nf });
        }
        if (t >= @divTrunc(ticks * 2, 3)) {
            w += 1;
            for (0..lepton.n) |i| {
                const b: usize = @intFromFloat(@floor(grid3.radius(i)));
                if (b >= bins) continue;
                cnt[b] += 1;
                if (lep_grid.fired[i]) rate[b] += 1;
                agr[b] += lep_grid.agreement(i);
            }
        }
    }
    std.debug.print("\n  profile, last third:  dist  flash  agree\n", .{});
    for (1..bins) |b| std.debug.print("                        {d:>4}  {d:.3}  {d:.3}\n", .{ b, rate[b] / cnt[b], agr[b] / cnt[b] });
}

var control_grid: record.Control = undefined;

fn recordRun(io: std.Io, gpa: std.mem.Allocator, args: anytype) !void {
    var mode: []const u8 = "lattice";
    var disp_s: []const u8 = "one_cell";
    var update: []const u8 = "sync";
    var core: u32 = 0;
    var ticks: i64 = 1500;
    var every: i64 = 10;
    var gravity = false;
    var seed: u64 = 20261110;
    var p: f64 = 0.2;
    while (args.next()) |a| {
        const eq = std.mem.indexOfScalar(u8, a, '=') orelse continue;
        const k = a[0..eq];
        const v = a[eq + 1 ..];
        if (std.mem.eql(u8, k, "mode")) mode = v
        else if (std.mem.eql(u8, k, "display")) disp_s = v
        else if (std.mem.eql(u8, k, "update")) update = v
        else if (std.mem.eql(u8, k, "core")) core = try std.fmt.parseInt(u32, v, 10)
        else if (std.mem.eql(u8, k, "ticks")) ticks = try std.fmt.parseInt(i64, v, 10)
        else if (std.mem.eql(u8, k, "every")) every = @max(1, try std.fmt.parseInt(i64, v, 10))
        else if (std.mem.eql(u8, k, "gravity")) gravity = std.mem.eql(u8, v, "on")
        else if (std.mem.eql(u8, k, "seed")) seed = try std.fmt.parseInt(u64, v, 10)
        else if (std.mem.eql(u8, k, "p")) p = try std.fmt.parseFloat(f64, v);
    }
    const is_lattice = std.mem.eql(u8, mode, "lattice");
    if (!is_lattice) {
        disp_s = "one_cell";
        update = "sync";
        gravity = false;
    }
    if (std.mem.eql(u8, mode, "control")) {
        const cname = try std.fmt.allocPrint(gpa, "control_p{d}_t{d}_s{d}", .{ p, ticks, seed });
        defer gpa.free(cname);
        const cmeta: record.Meta = .{ .name = cname, .mode = "control", .display = "none", .update = "none", .core = 0, .gravity = false, .seed = seed, .ticks = ticks, .every = every, .rules = "CONTROL: fixed chance p per pixel per tick, not the engine" };
        control_grid.init(seed, p);
        const cdir = try record.run(io, gpa, &control_grid, cmeta, "results/runs");
        defer gpa.free(cdir);
        std.debug.print("wrote {s}/\n", .{cdir});
        return;
    }
    const name = if (is_lattice)
        try std.fmt.allocPrint(gpa, "lattice_{s}_{s}_core{d}_{s}_t{d}_s{d}", .{ disp_s, update, core, if (gravity) "grav" else "nograv", ticks, seed })
    else
        try std.fmt.allocPrint(gpa, "{s}_core{d}_t{d}_s{d}", .{ mode, core, ticks, seed });
    defer gpa.free(name);
    const rules = if (is_lattice)
        (if (gravity) "1-5 + 6 (gravity: 3 carrier units -> +1 reinforce per cell); carrier lost at box edge" else "1-5; carrier lost at box edge, no feedback")
    else if (std.mem.eql(u8, mode, "v1")) "1-4, 7, 8, 9 (carrier always 'electron')"
    else if (std.mem.eql(u8, mode, "signed")) "1-4, 7, 8, 10 (signed carrier)"
    else if (std.mem.eql(u8, mode, "turing")) "1-4, 7, 8, 11 (carrier cancels memory)"
    else return error.UnknownMode;
    const meta: record.Meta = .{ .name = name, .mode = mode, .display = disp_s, .update = update, .core = core, .gravity = gravity, .seed = seed, .ticks = ticks, .every = every, .rules = rules };
    const start: engine.Start = if (core == 0) .random else .{ .core = core };
    const dir = if (is_lattice) blk: {
        lattice.init(.{
            .display = std.meta.stringToEnum(engine.Display, disp_s) orelse return error.UnknownDisplay,
            .update = std.meta.stringToEnum(engine.Update, update) orelse return error.UnknownUpdate,
            .start = start,
            .seed = seed,
        });
        lattice.gravity = gravity;
        break :blk try record.run(io, gpa, &lattice, meta, "results/runs");
    } else blk: {
        lep_grid.init(seed, core);
        lep_grid.signed = std.mem.eql(u8, mode, "signed");
        lep_grid.turing = std.mem.eql(u8, mode, "turing");
        break :blk try record.run(io, gpa, &lep_grid, meta, "results/runs");
    };
    defer gpa.free(dir);
    std.debug.print("wrote {s}/ (meta.json series.csv shells.csv gaps.csv slice.csv)\n", .{dir});
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
    } else if (std.mem.eql(u8, command, "generations")) {
        generationsReport();
    } else if (std.mem.eql(u8, command, "universality")) {
        universalityReport();
    } else if (std.mem.eql(u8, command, "export")) {
        std.debug.print("\n========================================\n          DATASET EXPORT\n========================================\n\n", .{});
        export_.run(init.io, init.gpa) catch |err| fail(err);
    } else if (std.mem.eql(u8, command, "majorana")) {
        majoranaReport();
    } else if (std.mem.eql(u8, command, "charge")) {
        chargeReport();
    } else if (std.mem.eql(u8, command, "weak")) {
        weakReport(init.io, init.gpa, &args) catch |err| fail(err);
    } else if (std.mem.eql(u8, command, "structure")) {
        structurePage(init.io, init.gpa, &args) catch |err| fail(err);
    } else if (std.mem.eql(u8, command, "app")) {
        app(init.io, init.gpa, &args) catch |err| fail(err);
    } else if (std.mem.eql(u8, command, "chart")) {
        chart(init.io, init.gpa, &args) catch |err| fail(err);
    } else if (std.mem.eql(u8, command, "project")) {
        projectReport(&args);
    } else if (std.mem.eql(u8, command, "record")) {
        recordRun(init.io, init.gpa, &args) catch |err| fail(err);
    } else if (std.mem.eql(u8, command, "lepton")) {
        leptonReport(&args);
    } else if (std.mem.eql(u8, command, "lattice3")) {
        lattice3Report(&args);
    } else if (std.mem.eql(u8, command, "clocks")) {
        clocksReport(&args);
    } else if (std.mem.eql(u8, command, "engine")) {
        engineReport(&args);
    } else if (std.mem.eql(u8, command, "koide")) {
        koideReport();
    } else {
        std.debug.print("Unknown command: {s}\n", .{command});
        help();
    }
}
