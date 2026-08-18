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

    // MARK: - The cat

    /// The cat prowls a circle round the CRANE — this is its radius, in metres, measured
    /// from the crane frame's origin (the midpoint of the two gear centres).
    ///
    /// 20cm is chosen against what it must not touch. The widest pair the level can
    /// detect puts the gear centres about 4cm either side of that origin and the cheese
    /// hangs within the same span, so at 20cm the cat's path clears every virtual object
    /// in the scene by more than its own body length — it cannot intersect the gears, the
    /// rope or the cheese at any point on the lap. It is also close enough to stay in
    /// frame while the child is looking at the crane, which a wider ring would not.
    static let catOrbitRadius: Double = 0.20

    /// The half of the circle the cat is allowed on: the FRONT half, in front of the beam.
    ///
    /// `place` puts the cat at (r·cos θ, 0, r·sin θ) in crane-local axes, where +Z points
    /// out of the beam's face toward the child — so θ from 0 to π is a sweep from one side
    /// of the crane, round the front, to the other side, and never behind it. The cat turns
    /// round at each end (`OrbitPatrolModel`'s `arc`) instead of continuing into the back
    /// half, where it was being drawn over the crane, the gears and the mouse.
    ///
    /// The bounds are ON the beam's own axis rather than short of it, so the cat's beat is
    /// as wide as it can be without ever crossing behind: at both ends it stands beside the
    /// crane at `catOrbitRadius`, clear of every part of it.
    static let catOrbitArc: ClosedRange<Double> = 0...(.pi)

    /// The cat's ground speed, in metres per second — a lap in about 13 seconds, which is
    /// roughly the length of one attempt. Slower than the cutscene's prowl relative to its
    /// circle on purpose: here the cat is atmosphere beside a task, not the subject of the
    /// shot, and anything faster pulls the eye off the gears.
    static let catOrbitSpeed: Double = 0.10

    /// Scale applied to the cat ON TOP of the ratio authored in `meong.usdz`, which
    /// `CutsceneStageEntity` resolves to a cat about 14cm long and 11cm tall.
    ///
    /// The authored ratio is the designer's and is not ours to re-derive (see that file's
    /// header, and why there is deliberately no `catBodyLength` constant). But the
    /// cutscene's cat is sized to be the subject of its own frame, and Level 2's must sit
    /// beside a crane without dominating it: 0.78 brings it to about 11cm long and 8.5cm
    /// tall — half again the mouse's 5.5cm, so it still reads as the bigger animal, while
    /// staying shorter than the crane's own column. This is THE knob for the cat's size on
    /// device; nothing else here needs to move with it.
    static let catScale: Float = 0.78
}
