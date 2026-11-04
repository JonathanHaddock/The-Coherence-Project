const std = @import("std");
const detector = @import("visualization/detector.zig");

const constants = @import("science/constants.zig");
const units = @import("science/units.zig");
const particles = @import("science/particles.zig");
const observations = @import("science/observations.zig");
const koide = @import("analysis/koide.zig");
const kinematics = @import("analysis/kinematics.zig");
const manifest = @import("dataset/manifest.zig");
const events = @import("dataset/events.zig");
const store = @import("dataset/store.zig");
const spectrum = @import("analysis/spectrum.zig");
const spectrum_svg = @import("visualization/spectrum_svg.zig");

test {
    _ = koide;
    _ = kinematics;
    _ = manifest;
    _ = events;
    _ = store;
    _ = spectrum;
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
        \\  origin help
        \\
    , .{});
}

fn info() void {
    std.debug.print(
        \\
        \\ORIGIN SYSTEM INFORMATION
        \\
        \\Version:       0.3.0
        \\Language:      Zig 0.17.0
        \\Platform:      macOS
        \\Storage:       Local
        \\Interface:     Terminal
        \\
        \\Scientific modules: ONLINE
        \\Particle catalogue: ONLINE
        \\Dataset engine:     PENDING
        \\Analysis engine:    INITIALIZING
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

fn koideFamily(label: []const u8, a: particles.Particle, b: particles.Particle, c: particles.Particle) void {
    const q = koide.ratio(a.mass_kg, b.mass_kg, c.mass_kg);
    std.debug.print("  {s:<18} Q = {d:.6}   angle = {d:>8.4} deg   Q - 2/3 = {e:>10.3}\n", .{
        label, q, koide.angleDegrees(a.mass_kg, b.mass_kg, c.mass_kg), q - 2.0 / 3.0,
    });
}

fn koideReport() void {
    std.debug.print(
        \\
        \\========================================
        \\          KOIDE ANALYSIS
        \\========================================
        \\
        \\Q = (m1+m2+m3) / (sqrt m1 + sqrt m2 + sqrt m3)^2
        \\Range: 1/3 (equal masses) to 1 (one mass dominates).
        \\Q = 2/3 is a 45 degree angle to (1,1,1).
        \\
        \\FERMION FAMILIES
        \\
    , .{});

    koideFamily("Charged leptons", particles.electron, particles.muon, particles.tau);
    koideFamily("Up-type quarks", particles.up, particles.charm, particles.top);
    koideFamily("Down-type quarks", particles.down, particles.strange, particles.bottom);

    std.debug.print(
        \\
        \\NEUTRINOS (masses unknown; scanning the lightest mass m1)
        \\Normal ordering, NuFIT 6.0: dm21^2 = {e:.3} eV^2, dm31^2 = {e:.3} eV^2
        \\
        \\  m1 (eV)      m2 (eV)      m3 (eV)      Q
        \\
    , .{ koide.nu_dm21_sq, koide.nu_dm31_sq });

    const scan = [_]f64{ 0.0, 0.001, 0.003, 0.01, 0.03, 0.1 };
    for (scan) |m1| {
        const n = koide.neutrinoMasses(m1);
        std.debug.print("  {d:<12.4} {d:<12.5} {d:<12.5} {d:.6}\n", .{ n[0], n[1], n[2], koide.ratio(n[0], n[1], n[2]) });
    }

    std.debug.print(
        \\
        \\  Q falls from {d:.4} toward 1/3 as m1 grows. Q = 2/3 is not reachable
        \\  in normal ordering, so a Koide-like neutrino relation needs another form.
        \\
        \\NOTE: quark masses are scheme-dependent (MS-bar vs pole); treat quark Q as indicative.
        \\
    , .{koide.ratio(koide.neutrinoMasses(0.0)[0], koide.neutrinoMasses(0.0)[1], koide.neutrinoMasses(0.0)[2])});
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
    } else if (std.mem.eql(u8, command, "koide")) {
        koideReport();
    } else {
        std.debug.print("Unknown command: {s}\n", .{command});
        help();
    }
}
