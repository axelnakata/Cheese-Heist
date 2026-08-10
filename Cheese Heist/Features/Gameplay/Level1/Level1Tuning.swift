// Level1Tuning.swift — Cheese Heist
// PRD-Level1 §6 — physics constants for Level 1.
// Level 1 is unfailable: every pair of gears must lift.

import Foundation

enum Level1Tuning {

    static let value = LevelTuning(
        payloadMass: 0.010,          // 10 g cheese — unfailable at every pair
        stallTorque: 0.006,          // 6 mN·m mouse
        noLoadAngularVelocity: 12.0, // rad/s, ~1.9 rev/s unloaded
        meshEfficiency: 0.94,        // single spur mesh
        winchRadius: 0.0025,         // LEGO axle, in metres
        liftHeight: 0.06,            // 6 cm of travel
        minLiftDuration: 1.2         // presentation floor on rope speed, seconds
    )
}
