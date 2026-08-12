//
//  GearOrdering.swift
//  Cheese Heist
//
//  The one rule the tracker and all of its callers use to decide which gear is which
//  across frames. Pulled out into its own type precisely because more than one place
//  needs it and they must not drift apart.
//

import Foundation
import simd

enum GearOrdering {

    /// Tooth count first, because it is viewpoint-independent and the two gears in
    /// this app always differ. Screen X only breaks ties, which is why an equal-tooth
    /// pair would not survive the child walking around to the far side — out of scope
    /// while the model's classes are distinct tooth counts.
    static func ordered(_ detections: [GearDetection]) -> [GearDetection] {
        detections.sorted { lhs, rhs in
            if lhs.toothCount != rhs.toothCount { return lhs.toothCount < rhs.toothCount }
            return lhs.centerPixel.x < rhs.centerPixel.x
        }
    }

    /// Same rule, applied to gears that already carry world positions.
    static func ordered(_ gears: [DetectedGear]) -> [DetectedGear] {
        gears.sorted { $0.toothCount < $1.toothCount }
    }

    /// The gears as the CHILD sees them, left to right.
    ///
    /// The crane frame's local +X *is* screen right: `right = up x normal` and the
    /// normal is solved to point back at the camera, so the gear with the smaller local
    /// X is the one on the left of the iPad — from wherever the child happens to be
    /// standing, without projecting anything.
    ///
    /// READ ONCE, AT LOCK, AND THEN FROZEN. Walking round to the far side of the crane
    /// genuinely does swap which gear is on the left, and the roles must not swap with
    /// it: this decides where the mouse starts, not where it lives.
    static func leftToRight(_ gears: [DetectedGear], in frame: CraneFrame) -> [DetectedGear] {
        gears.sorted {
            frame.localPoint($0.worldPosition).x < frame.localPoint($1.worldPosition).x
        }
    }
}
