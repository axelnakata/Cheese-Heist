//
//  HorizontalNormalSolver.swift
//  Cheese Heist
//
//  Which way the beam faces, from two gear centres and gravity.
//
//  This needs no plane fit and no depth map to interpret — the beam runs through both
//  gears by construction, and the gears are what the detector is best at finding.
//  Stateless geometry, and it does not care whether the points came from a depth
//  probe or from `CranePairCompleter`.
//

import simd

enum HorizontalNormalSolver {

    /// Horizontal span the gear pair must have before the line between them is allowed
    /// to set the facing direction.
    ///
    /// Two gears stacked vertically have no horizontal span, and their line then says
    /// nothing about which way the beam runs — the horizontal component that survives
    /// is pure box noise, amplified by being divided by almost nothing. 4mm against a
    /// 24mm spacing means the pair is at least ~10 degrees off vertical.
    static let minimumHorizontalSeparation: Float = 0.004

    /// The beam's outward normal as a horizontal unit vector pointing at the viewer,
    /// or nil if these two points cannot say.
    static func normal(
        from positions: [simd_float3], toward camera: simd_float3
    ) -> simd_float3? {
        guard positions.count == 2 else { return nil }

        let beam = positions[1] - positions[0]
        var right = simd_float3(beam.x, 0, beam.z)
        let length = simd_length(right)

        // Gears stacked vertically rather than side by side — the horizontal direction
        // is then unmeasurable and the caller should keep its running estimate.
        guard length > 1e-4 else { return nil }
        right /= length

        // `CraneFrame` is built as right = up x normal, which inverts to this.
        var normal = simd_cross(right, simd_float3(0, 1, 0))

        // Two directions satisfy that; the scene is only ever viewed from one side, so
        // take the one facing the camera.
        let midpoint = (positions[0] + positions[1]) / 2
        if simd_dot(normal, camera - midpoint) < 0 { normal = -normal }

        return simd_normalize(normal)
    }

    /// Whether this pair is spread widely enough for `normal(from:toward:)` to mean
    /// anything.
    static func hasUsableSpan(_ first: simd_float3, _ second: simd_float3) -> Bool {
        let span = simd_float3(second.x - first.x, 0, second.z - first.z)
        return simd_length(span) >= minimumHorizontalSeparation
    }
}
