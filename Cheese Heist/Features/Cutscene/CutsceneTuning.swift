//
//  CutsceneTuning.swift
//  Cheese Heist
//
//  Measured data and design decisions for the cutscene.
//
//  Mirrors `CraneAlignmentTuning` and `Level1Tuning` — these are constants, not knobs.
//  Every number is either measured on device or specified in the PRD. The ones marked
//  CALIBRATE are still guesses and need one pass on hardware before they are data.
//

import Foundation

enum CutsceneTuning {
    // MARK: - Cat

    /// Cat's body length, in metres. Specified by the team, not measured (OQ-C2).
    ///
    /// Worth an eye on device: at 20 cm the cat is longer than the 18 cm radius of the
    /// circle it walks, so it will read as a large animal pacing a tight ring. That may
    /// be exactly the intimidation the beat wants, or it may look like a scale error.
    /// Changing it here changes nothing else — the orbit is driven in code.
    static let catBodyLength: Float = 0.20

    /// Yaw applied to the cat so its nose points along the direction of travel.
    ///
    /// CALIBRATE. The RCP-authored axis correction in `meong.usdz` fixes the cat's own
    /// export rotations, but "forward" along the orbit is a separate question from
    /// "upright" — it still has to be looked at. Quarter-turns here are cheap: if the
    /// cat orbits sideways, this is the only number that needs to move.
    static let catForwardYaw: Float = 0

    /// Orbit radius around the cheese, in metres (PRD-Cutscene §6.3).
    static let orbitRadius: Double = 0.18

    /// Cat's ground speed around the orbit, in metres per second (PRD-Cutscene §6.3).
    static let orbitSpeed: Double = 0.04

    /// How fast the cat swings round to a new heading, in radians per second. Snapping
    /// the orientation every frame made the walk look like a turntable.
    static let catTurnRate: Float = 4.0

    /// The walk cycle's slice of the cat's baked take, in seconds.
    ///
    /// The cat (`tooncat`, inside `meong.usdz`) carries exactly one take — `Action`,
    /// frames 1–21 at 24 fps in the source `.usda` (≈0.833 s) — so the "slice" is the
    /// whole take rather than a cut out of a longer performance. CALIBRATE: confirm
    /// against the duration `CatEntity` logs at runtime (`Logger.cutscene`, "cat
    /// takes: …") on first device run and correct if RealityKit reports it differently.
    static let catWalkClipStart: TimeInterval = 0
    static let catWalkClipEnd: TimeInterval = 0.8333

    // MARK: - Cheese

    /// Cheese longest edge in the cutscene, in metres.
    /// Larger than Level 1's 4.8 cm because there is no crane next to it for scale.
    static let cheeseSize: Float = 0.08

    // MARK: - Surface detection

    /// How often the raycast probe actually fires, in seconds. The ticker runs at 60 Hz;
    /// raycasting that often is wasted work and reads as jitter.
    static let surfaceSampleInterval: Float = 1.0 / 12.0

    /// How many agreeing probes are needed before the verdict changes. At 12 Hz this is
    /// about a third of a second of steadiness.
    static let surfaceStabilitySamples = 4
}
