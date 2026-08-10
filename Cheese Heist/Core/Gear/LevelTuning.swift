// LevelTuning.swift — Cheese Heist
// PRD §6.6 — every physics constant the simulation needs, per level.
// The TYPE lives in Core/Gear; the VALUES live in each level's folder.

struct LevelTuning: Equatable, Sendable {
    /// Cheese mass, in kg.
    let payloadMass: Double
    /// Mouse torque at stall, in N·m.
    let stallTorque: Double
    /// Mouse angular velocity with no load, in rad/s.
    let noLoadAngularVelocity: Double
    /// Single spur mesh efficiency (0…1).
    let meshEfficiency: Double
    /// LEGO axle winding radius, in metres.
    let winchRadius: Double
    /// Target lift height, in metres.
    let liftHeight: Double
    /// Presentation floor — minimum on-screen lift time, in seconds.
    let minLiftDuration: Double

    /// τ_load = m_cheese · g · r_drum
    var loadTorque: Double {
        payloadMass * 9.81 * winchRadius
    }
}
