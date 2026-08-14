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
        liftHeight: 0.06             // fallback — travel is measured off the crane
    )

    /// How long the child has to lift the cheese, in seconds.
    static let timerDuration: Int = 15

    /// How long the gear-clash shake plays before a stalled combo fails, in seconds.
    static let stallShakeDuration: Double = 5.0

    /// Peak wobble angle of the gear-clash shake, in radians. Small on purpose — "not
    /// too dramatic," a strain, not a spin. ~3°.
    static let stallShakeAmplitudeRadians: Double = 0.05

    /// How fast the wobble oscillates, in Hz.
    static let stallShakeFrequencyHz: Double = 6.0
}
