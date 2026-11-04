pub const ParticleType = enum {
    electron,
    muon,
    tau,
    up_quark,
    down_quark,
    proton,
    neutron,
    photon,
};

pub const Particle = struct {
    name: []const u8,
    symbol: []const u8,
    mass_kg: f64,
    charge_e: f64,
};

pub const electron = Particle{
    .name = "Electron",
    .symbol = "e-",
    .mass_kg = 9.1093837139e-31,
    .charge_e = -1.0,
};

pub const muon = Particle{
    .name = "Muon",
    .symbol = "mu-",
    .mass_kg = 1.883531627e-28,
    .charge_e = -1.0,
};

pub const tau = Particle{
    .name = "Tau",
    .symbol = "tau-",
    .mass_kg = 3.16754e-27,
    .charge_e = -1.0,
};

pub const proton = Particle{
    .name = "Proton",
    .symbol = "p",
    .mass_kg = 1.67262192595e-27,
    .charge_e = 1.0,
};

pub const neutron = Particle{
    .name = "Neutron",
    .symbol = "n",
    .mass_kg = 1.67492750056e-27,
    .charge_e = 0.0,
};

pub const photon = Particle{
    .name = "Photon",
    .symbol = "gamma",
    .mass_kg = 0.0,
    .charge_e = 0.0,
};
