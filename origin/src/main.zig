const std = @import("std");
const detector = @import("visualization/detector.zig");

const constants = @import("science/constants.zig");
const units = @import("science/units.zig");
const particles = @import("science/particles.zig");
const observations = @import("science/observations.zig");

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
        \\  origin analyze
        \\  origin help
        \\
    , .{});
}

fn info() void {
    std.debug.print(
        \\
        \\ORIGIN SYSTEM INFORMATION
        \\
        \\Version:       0.2.0
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
        \\LEPTONS
        \\  Electron  e-
        \\  Muon      mu-
        \\  Tau       tau-
        \\
        \\HADRONS
        \\  Proton    p
        \\  Neutron   n
        \\
        \\BOSONS
        \\  Photon    gamma
        \\
        \\Total registered particles: 6
        \\
    , .{});
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
        \\Particle entries: 6
        \\
    , .{
        units.metersToKilometers(1000.0),
        observations.positionMagnitude(vector),
    });
}

fn dataset() void {
    std.debug.print(
        \\
        \\========================================
        \\          DATASET ENGINE
        \\========================================
        \\
        \\Storage mode: LOCAL
        \\Raw datasets:       data/raw/
        \\Processed datasets: data/processed/
        \\Manifests:          data/manifests/
        \\Results:            results/
        \\
        \\Dataset engine: NOT IMPLEMENTED
        \\
    , .{});
}

fn analyze() void {
    const vector = observations.Vector3{
        .x = 3.0,
        .y = 4.0,
        .z = 0.0,
    };

    std.debug.print(
        \\
        \\========================================
        \\          ORIGIN ANALYSIS
        \\========================================
        \\
        \\VECTOR ANALYSIS
        \\
        \\X: 3
        \\Y: 4
        \\Z: 0
        \\Magnitude: {}
        \\
        \\Analysis status: BASIC CALCULATION
        \\
    , .{
        observations.positionMagnitude(vector),
    });
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
        dataset();
    } else if (std.mem.eql(u8, command, "analyze")) {
        analyze();
    } else if (std.mem.eql(u8, command, "observe")) {
        const name = args.next() orelse {
            std.debug.print("Usage: origin observe <particle>\n", .{});
            return;
        };

        if (std.mem.eql(u8, name, "electron")) {
            observe(particles.electron);
        } else if (std.mem.eql(u8, name, "muon")) {
            observe(particles.muon);
        } else if (std.mem.eql(u8, name, "tau")) {
            observe(particles.tau);
        } else if (std.mem.eql(u8, name, "proton")) {
            observe(particles.proton);
        } else if (std.mem.eql(u8, name, "neutron")) {
            observe(particles.neutron);
        } else if (std.mem.eql(u8, name, "photon")) {
            observe(particles.photon);
        } else {
            std.debug.print("Unknown particle: {s}\n", .{name});
        }
    } else {
        std.debug.print("Unknown command: {s}\n", .{command});
        help();
    }
}
