//! Two-group homogenized macroscopic cross sections (units: cm, 1/cm).
//!
//! These are ILLUSTRATIVE teaching values of the kind used in textbook
//! problems (Duderstadt & Hamilton, Lamarsh). They are not taken from any
//! real design and are not suitable for engineering use. Group 1 is fast,
//! group 2 is thermal; all fission neutrons are born fast (chi = [1, 0]).

const std = @import("std");

pub const Material = struct {
    name: []const u8,
    note: []const u8,
    d1: f64, // fast diffusion coefficient
    d2: f64, // thermal diffusion coefficient
    sa1: f64, // fast absorption
    sa2: f64, // thermal absorption
    s12: f64, // fast -> thermal downscatter (removal)
    nsf1: f64, // nu * fast fission
    nsf2: f64, // nu * thermal fission
    sf1: f64, // fast fission (for power shape)
    sf2: f64, // thermal fission

    /// Infinite-medium multiplication factor.
    pub fn kInf(m: Material) f64 {
        if (m.nsf1 == 0 and m.nsf2 == 0) return 0;
        return (m.nsf1 + m.nsf2 * m.s12 / m.sa2) / (m.sa1 + m.s12);
    }

    /// Migration area M^2 = L1^2 + L2^2 (cm^2).
    pub fn migrationArea(m: Material) f64 {
        return m.d1 / (m.sa1 + m.s12) + m.d2 / m.sa2;
    }
};

pub const lwr_fuel = Material{
    .name = "lwr",
    .note = "homogenized light-water lattice (teaching values)",
    .d1 = 1.43,
    .d2 = 0.37,
    .sa1 = 0.0101,
    .sa2 = 0.0805,
    .s12 = 0.0172,
    .nsf1 = 0.0063,
    .nsf2 = 0.1355,
    .sf1 = 0.0025,
    .sf2 = 0.0556,
};

pub const water = Material{
    .name = "water",
    .note = "light-water reflector",
    .d1 = 1.13,
    .d2 = 0.16,
    .sa1 = 0.0004,
    .sa2 = 0.0197,
    .s12 = 0.0494,
    .nsf1 = 0,
    .nsf2 = 0,
    .sf1 = 0,
    .sf2 = 0,
};

pub const graphite = Material{
    .name = "graphite",
    .note = "graphite reflector",
    .d1 = 1.02,
    .d2 = 0.84,
    .sa1 = 0.00003,
    .sa2 = 0.00027,
    .s12 = 0.0035,
    .nsf1 = 0,
    .nsf2 = 0,
    .sf1 = 0,
    .sf2 = 0,
};

/// Fuel cell with a control rod inserted (homogenized, teaching values):
/// the lwr lattice plus a strong thermal absorber.
pub const rodded = Material{
    .name = "rodded",
    .note = "lwr lattice with control rod inserted",
    .d1 = 1.43,
    .d2 = 0.37,
    .sa1 = 0.0101 + 0.004,
    .sa2 = 0.0805 + 0.10,
    .s12 = 0.0172,
    .nsf1 = 0.0063,
    .nsf2 = 0.1355,
    .sf1 = 0.0025,
    .sf2 = 0.0556,
};

pub const all = [_]Material{ lwr_fuel, water, graphite, rodded };

pub fn find(name: []const u8) ?Material {
    for (all) |m| if (std.ascii.eqlIgnoreCase(m.name, name)) return m;
    return null;
}

test "lwr k_inf is supercritical, reflectors are not" {
    try std.testing.expect(lwr_fuel.kInf() > 1.2 and lwr_fuel.kInf() < 1.4);
    try std.testing.expectEqual(@as(f64, 0), water.kInf());
}
