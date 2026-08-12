// ActuatorModel.swift — Cheese Heist
// PRD §6.4 — the mouse is a torque source with a linear torque-speed curve.
// τ_driver(ω) = τ_stall · (1 − ω_driver / ω_noLoad)

import Foundation

enum ActuatorModel {

    /// Steady-state driver angular velocity under load.
    /// ω_driver = ω_noLoad · (1 − τ_load / (i · η · τ_stall))
    /// Clamped at 0 — the mouse cannot turn backwards.
    static func driverAngularVelocity(
        ratio: Double, tuning: LevelTuning
    ) -> Double {
        let effectiveTorque = ratio * tuning.meshEfficiency * tuning.stallTorque
        guard effectiveTorque > 0 else { return 0 }

        let factor = 1.0 - tuning.loadTorque / effectiveTorque
        return max(0, tuning.noLoadAngularVelocity * factor)
    }

    /// Whether the load can be lifted at all: i · η · τ_stall > τ_load.
    static func canLift(ratio: Double, tuning: LevelTuning) -> Bool {
        ratio * tuning.meshEfficiency * tuning.stallTorque > tuning.loadTorque
    }
}
