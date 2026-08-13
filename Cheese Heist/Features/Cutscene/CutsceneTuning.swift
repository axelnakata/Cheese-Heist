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
    /// CALIBRATE. `thundercat.usdz` carries a −90°-about-X correction from its Blender
    /// export, so which local axis ends up as "forward" is not something we can read off
    /// the file — it has to be looked at. Quarter-turns here are cheap: if the cat orbits
    /// sideways, this is the only number that needs to move.
    static let catForwardYaw: Float = 0

    /// Orbit radius around the cheese, in metres (PRD-Cutscene §6.3).
    static let orbitRadius: Double = 0.30

    /// Cat's ground speed around the orbit, in metres per second (PRD-Cutscene §6.3).
    static let orbitSpeed: Double = 0.04

    /// How fast the cat swings round to a new heading, in radians per second. Snapping
    /// the orientation every frame made the walk look like a turntable.
    static let catTurnRate: Float = 4.0

    /// The walk cycle's slice of `thundercat.usdz`'s baked take, in seconds.
    ///
    /// Straight out of `C5.usda`: the RealityKit `AnimationLibrary` there cuts the take
    /// `"default subtree animation"` at startTimes [0, 5.227722, 5.704193] and the
    /// timeline plays the middle slice — 0.4765 s — sixteen times over.
    static let catWalkClipStart: TimeInterval = 5.2277
    static let catWalkClipEnd: TimeInterval = 5.7042

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
