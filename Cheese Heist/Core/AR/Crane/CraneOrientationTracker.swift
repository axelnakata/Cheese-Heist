//
//  CraneOrientationTracker.swift
//  Cheese Heist
//
//  Owns `trackedNormal` — one of exactly two pieces of cross-frame state in the whole
//  crane solver, which is why it is its own type. Everything else about where the
//  gears are is re-derived from the rays of the frame being drawn, and that is what
//  makes the overlay a reflection rather than a memory.
//
//  ORIENTATION IS A PROPERTY OF A THING BOLTED TO A TABLE, so it is filtered hard and
//  costs no responsiveness — there is nothing for the filter to lag behind.
//

import simd

final class CraneOrientationTracker {

    /// How much of a measured facing direction to take per frame.
    ///
    /// The line between two measured gear centres can only be as wrong as the boxes
    /// are noisy — a degree or two — so this can be far higher than the beam plane fit
    /// it replaced, which had ninety-degree failure modes and had to be held to 0.12.
    static let blend: Float = 0.25

    /// The running estimate: a horizontal unit vector out of the beam's face.
    private(set) var trackedNormal: simd_float3?

    func reset() {
        trackedNormal = nil
    }

    /// Folds a measured facing direction into the running estimate.
    ///
    /// Blended rather than taken whole because the gear centres still wobble by a pixel
    /// or two, and across a 24mm span that wobble is a degree or so of heading.
    @discardableResult
    func absorb(measured: simd_float3) -> simd_float3 {
        guard let current = trackedNormal else {
            trackedNormal = measured
            return measured
        }

        // A measurement pointing away from the running estimate means the child has
        // gone round to the other side of the crane, where the face we started on is
        // no longer the one being seen. Blending it would collapse the average through
        // zero, so it is dropped and the existing orientation kept.
        guard simd_dot(current, measured) > 0 else { return current }

        let mixed = current + (measured - current) * Self.blend

        // Flattened for the same reason the measurement was: the crane stands on a
        // table, so any vertical component of the facing direction can only be error.
        let flat = simd_float3(mixed.x, 0, mixed.z)
        guard simd_length(flat) > 1e-4 else { return current }

        let result = simd_normalize(flat)
        trackedNormal = result
        return result
    }

    /// The facing direction to use when this frame supplied no usable measurement.
    ///
    /// SEED ONLY, NEVER A PER-FRAME FALLBACK. The camera's own direction is taken once,
    /// on the very first frame, because the child is asked to face the crane to scan it
    /// and so the crane faces back at them to within a few degrees. Folding the
    /// camera's direction in on every frame would make the crane's facing follow the
    /// child around the room, which is precisely the opposite of what a fixed object
    /// should do.
    func heldOrSeeded(cameraTransform: simd_float4x4) -> simd_float3? {
        if let tracked = trackedNormal { return tracked }

        let back = cameraTransform.columns.2      // ARKit cameras look along -Z
        let horizontal = simd_float3(back.x, 0, back.z)
        guard simd_length(horizontal) > 1e-4 else { return nil }

        let seeded = simd_normalize(horizontal)
        trackedNormal = seeded
        return seeded
    }
}
