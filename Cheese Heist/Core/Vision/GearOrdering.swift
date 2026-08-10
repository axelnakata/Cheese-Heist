//
//  GearOrdering.swift
//  Cheese Heist
//
//  The one rule the tracker and all of its callers use to decide which gear is which
//  across frames. Pulled out into its own type precisely because more than one place
//  needs it and they must not drift apart.
//

import Foundation

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
}
