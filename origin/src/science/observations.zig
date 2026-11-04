pub const Vector3 = struct {
    x: f64,
    y: f64,
    z: f64,
};

pub const Observation = struct {
    particle_id: u64,
    timestamp_seconds: f64,
    position_m: Vector3,
    momentum_kg_m_s: Vector3,
    energy_joules: f64,
    charge_e: f64,
};

pub fn momentumMagnitude(momentum: Vector3) f64 {
    return @sqrt(
        momentum.x * momentum.x +
        momentum.y * momentum.y +
        momentum.z * momentum.z
    );
}

pub fn positionMagnitude(position: Vector3) f64 {
    return @sqrt(
        position.x * position.x +
        position.y * position.y +
        position.z * position.z
    );
}
