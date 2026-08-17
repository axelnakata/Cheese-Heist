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
    static let stallShakeDuration: Double = 4.0

    /// Peak wobble angle of the gear-clash shake, in radians — a strain, not a spin.
    /// ~4.6° (0.08 rad): tuned moderately above initial 0.05 rad to ensure visible struggle
    /// without violent over-rotation.
    static let stallShakeAmplitudeRadians: Double = 0.08

    /// How fast the wobble oscillates, in Hz.
    static let stallShakeFrequencyHz: Double = 6.0

    /// A second, faster wobble layered on top of the first — see `GearShakeDriver`. Its
    /// frequency is not an integer multiple of `stallShakeFrequencyHz` so the sum never
    /// repeats cleanly, which is what reads as a grind rather than a metronome.
    static let stallShakeJitterAmplitudeRadians: Double = 0.035
    static let stallShakeJitterFrequencyHz: Double = 17.0

    /// How far the gears shove back and forth along the beam, in metres.
    /// 1mm (0.001m): gives subtle physical struggling feedback along the beam
    /// without appearing excessive or jarring.
    static let stallShakePositionJitterMeters: Double = 0.001
}
