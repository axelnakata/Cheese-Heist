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

    // There is no `catBodyLength` any more, and its absence is a decision (OQ-C2).
    //
    // The cat's size is not ours to set: it is the RCP-authored cat:cheese ratio inside
    // `meong.usdz`, and `CutsceneStageEntity` scales the whole stage as one unit off the
    // cheese. Sizing the cat independently is also what the old code could not do
    // correctly — a skinned mesh cannot be measured from `ModelBounds`, see that file.
    // At `cheeseSize` = 8 cm the cat comes out about 14 cm long and 11 cm tall. To make
    // the cat bigger, make the cheese bigger; the ratio is the designer's.

    /// Yaw applied to the cat so its nose points along the direction of travel.
    ///
    /// CALIBRATE, and it is the only thing left on this asset that has to be seen to be
    /// known. `CatOrbitDriver` assumes the cat's nose is +Z, because that is the axis the
    /// cat's length lies along once the stage's up-axis correction is dropped — but which
    /// END of that axis is the head cannot be read off a bounding box. If the cat walks
    /// its orbit backwards, this is the one number to move, and the move is `.pi`.
    static let catForwardYaw: Float = 0

    /// Orbit radius around the cheese, in metres (PRD-Cutscene §6.3).
    static let orbitRadius: Double = 0.30

    /// Cat's ground speed around the orbit, in metres per second.
    ///
    /// PRD-Cutscene §6.3 says 0.04, which is a real cat's amble and is the honest number
    /// — and at a 30 cm radius it is a 47-second lap. The beat it has to sell lasts about
    /// twenty seconds, so at 0.04 the child sees a cat that has drifted, not a cat that is
    /// circling the cheese, and the threat premise the beat is built on does not land.
    /// 0.12 walks the ring in ~16 s. Overrides §6.3 deliberately; this is the knob to
    /// turn if it reads as a scurry rather than a prowl.
    static let orbitSpeed: Double = 0.12

    /// How fast the cat swings round to a new heading, in radians per second. Snapping
    /// the orientation every frame made the walk look like a turntable.
    static let catTurnRate: Float = 4.0

    // The walk cycle is no longer trimmed: measured on the simulator, `meong.usdz`
    // exposes three takes all named "default subtree animation" — two 0.833 s bakes of
    // the cat's `Action` and one of duration `inf`. There is no longer performance to cut
    // a slice out of, so `CutsceneStageEntity` loops the longest finite take and the trim
    // constants that used to live here are gone.

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
