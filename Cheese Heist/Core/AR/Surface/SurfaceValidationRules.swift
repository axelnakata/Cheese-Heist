//
//  SurfaceValidationRules.swift
//  Cheese Heist
//
//  PRD-Cutscene §7.3 — pure geometry, no ARKit.
//
//  ═══ CLEARANCE AROUND THE HIT, NOT THE PLANE'S TOTAL SIZE. ═══
//
//  The first version asked "is the plane at least 0.40 m × 0.40 m", which is the wrong
//  question twice over. It rejects a large table whose ARKit plane has only partly grown
//  in — extents start small and creep outward as the child scans, so a perfectly good
//  table reads as invalid for as long as they hold still. And it accepts a hit right on
//  the edge of a big plane, where the cat would walk off into mid-air on its first lap.
//
//  What actually matters is how much flat surface surrounds the point the child is
//  aiming at. So the test is: from the hit, is there `requiredRadius` of plane in every
//  direction? That is the same question the ring on screen is asking, which means the
//  ring can no longer promise something the validity check did not measure.
//

import simd

enum SurfaceValidity: Equatable, Sendable {
    case valid
    case noSurface
    case tooSmall
    case tooClose
    case tooFar
}

enum SurfaceValidationRules {

    /// The circle the scene needs, in metres: the cat's orbit plus room for its body.
    /// Tied to the orbit radius on purpose — see `SurfaceRingEntity.outerRadius`.
    static let requiredRadius: Float = Float(CutsceneTuning.orbitRadius) + 0.04

    /// Closest the camera may be to the surface, in metres. Below this the cheese and
    /// cat do not both fit in frame.
    static let minimumDistance: Float = 0.25

    /// Furthest the camera may be, in metres. Beyond this the child is too far back for
    /// the scene to read, and tracking on a featureless table degrades.
    static let maximumDistance: Float = 1.20

    /// How much flat surface surrounds the hit, in metres — the distance from the hit
    /// point to the nearest edge of the plane's bounding rectangle.
    ///
    /// `halfExtent` and `offset` are both in the plane's own local XZ frame, so this
    /// stays pure: no world transforms, no ARKit types.
    static func clearance(halfExtent: SIMD2<Float>, offset: SIMD2<Float>) -> Float {
        let marginX = halfExtent.x - abs(offset.x)
        let marginZ = halfExtent.y - abs(offset.y)
        return min(marginX, marginZ)
    }

    /// PURE — no ARKit. This is the unit-tested part.
    ///
    /// Distance is checked before size: a surface that is too close or too far is a
    /// framing problem the child fixes by moving, and telling them it is "too small"
    /// would send them hunting for a different table instead.
    static func evaluate(clearance: Float, distance: Float) -> SurfaceValidity {
        if distance < minimumDistance { return .tooClose }
        if distance > maximumDistance { return .tooFar }
        if clearance < requiredRadius { return .tooSmall }
        return .valid
    }
}
