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

    /// τ_load = m_cheese · g · r_drum
    var loadTorque: Double {
        payloadMass * 9.81 * winchRadius
    }

    /// The same tuning with a different travel.
    ///
    /// `liftHeight` is the one constant here that is not a property of the mouse or the
    /// gears — it is a property of the CRANE, and the crane is built by a child out of
    /// bricks. `LiftRunner` substitutes the measured drop so that the ceiling, the
    /// designed rope speed and the progress fraction all agree about how far this
    /// particular cheese has to go.
    func lifting(to height: Double) -> LevelTuning {
        LevelTuning(
            payloadMass: payloadMass,
            stallTorque: stallTorque,
            noLoadAngularVelocity: noLoadAngularVelocity,
            meshEfficiency: meshEfficiency,
            winchRadius: winchRadius,
            liftHeight: height
        )
    }
}
