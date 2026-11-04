const std = @import("std");

pub const Family = enum {
    lepton,
    up_quark,
    down_quark,
    hadron,
    boson,

    pub fn label(self: Family) []const u8 {
        return switch (self) {
            .lepton => "LEPTONS",
            .up_quark => "UP-TYPE QUARKS",
            .down_quark => "DOWN-TYPE QUARKS",
            .hadron => "HADRONS",
            .boson => "BOSONS",
        };
    }
};

/// 1 MeV/c^2 in kilograms.
pub const mev_to_kg = 1.78266192e-30;

pub const Particle = struct {
    family: Family,
    name: []const u8,
    symbol: []const u8,
    mass_kg: f64,
    charge_e: f64,
};

pub const electron = Particle{
    .family = .lepton,
    .name = "Electron",
    .symbol = "e-",
    .mass_kg = 9.1093837139e-31,
    .charge_e = -1.0,
};

pub const muon = Particle{
    .family = .lepton,
    .name = "Muon",
    .symbol = "mu-",
    .mass_kg = 1.883531627e-28,
    .charge_e = -1.0,
};

pub const tau = Particle{
    .family = .lepton,
    .name = "Tau",
    .symbol = "tau-",
    .mass_kg = 3.16754e-27,
    .charge_e = -1.0,
};

pub const proton = Particle{
    .family = .hadron,
    .name = "Proton",
    .symbol = "p",
    .mass_kg = 1.67262192595e-27,
    .charge_e = 1.0,
};

pub const neutron = Particle{
    .family = .hadron,
    .name = "Neutron",
    .symbol = "n",
    .mass_kg = 1.67492750056e-27,
    .charge_e = 0.0,
};

pub const photon = Particle{
    .family = .boson,
    .name = "Photon",
    .symbol = "gamma",
    .mass_kg = 0.0,
    .charge_e = 0.0,
};

// Quark masses: PDG 2024 central values, MeV. Light quarks (u, d, s) are
// MS-bar at 2 GeV, c and b are MS-bar at their own mass, t is the direct
// (pole-like) measurement. Quark masses are scheme-dependent, so Koide
// results for quarks carry that ambiguity.
fn quark(family: Family, name: []const u8, symbol: []const u8, mass_mev: f64, charge_e: f64) Particle {
    return .{ .family = family, .name = name, .symbol = symbol, .mass_kg = mass_mev * mev_to_kg, .charge_e = charge_e };
}

pub const up = quark(.up_quark, "Up", "u", 2.16, 2.0 / 3.0);
pub const charm = quark(.up_quark, "Charm", "c", 1273.0, 2.0 / 3.0);
pub const top = quark(.up_quark, "Top", "t", 172570.0, 2.0 / 3.0);
pub const down = quark(.down_quark, "Down", "d", 4.70, -1.0 / 3.0);
pub const strange = quark(.down_quark, "Strange", "s", 93.5, -1.0 / 3.0);
pub const bottom = quark(.down_quark, "Bottom", "b", 4183.0, -1.0 / 3.0);

pub const catalogue = [_]Particle{ electron, muon, tau, up, charm, top, down, strange, bottom, proton, neutron, photon };

/// Case-insensitive lookup by name ("muon") or symbol ("mu-").
pub fn find(query: []const u8) ?Particle {
    for (catalogue) |p| {
        if (std.ascii.eqlIgnoreCase(query, p.name) or std.ascii.eqlIgnoreCase(query, p.symbol)) return p;
    }
    return null;
}
