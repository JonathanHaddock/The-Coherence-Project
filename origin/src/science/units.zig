pub const Length = f64;
pub const Mass = f64;
pub const Time = f64;
pub const Velocity = f64;
pub const Momentum = f64;
pub const Energy = f64;
pub const Charge = f64;

pub fn metersToKilometers(value: Length) Length {
    return value / 1000.0;
}

pub fn kilometersToMeters(value: Length) Length {
    return value * 1000.0;
}

pub fn joulesToElectronVolts(value: Energy) Energy {
    return value / 1.602176634e-19;
}

pub fn electronVoltsToJoules(value: Energy) Energy {
    return value * 1.602176634e-19;
}
