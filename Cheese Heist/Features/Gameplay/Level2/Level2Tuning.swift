// Level2Tuning.swift — Cheese Heist
// PRD-Level2 §5.1 — physics constants for Level 2.
// Level 2 is failable: some pairs stall, and a 15-second timer applies.

import Foundation

enum Level2Tuning {

    static let value = LevelTuning(
        payloadMass: 0.120,          // 120g — heavy enough that small-drives-big stalls
        stallTorque: 0.006,          // same mouse as L1
        noLoadAngularVelocity: 12.0, // same mouse as L1
        meshEfficiency: 0.94,        // single spur mesh
        winchRadius: 0.0025,         // LEGO axle
        liftHeight: 0.06,            // fallback — travel is measured off the crane
        minLiftDuration: 1.2,        // presentation floor
        maxLiftDuration: 15.0        // ceiling
    )

    /// How long the child has to lift the cheese, in seconds.
    static let timerDuration: Int = 15
}
