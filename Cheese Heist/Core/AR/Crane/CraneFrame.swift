//
//  CraneFrame.swift
//  Cheese Heist
//
//  The crane's own coordinate system, in world space.
//
//  Local +X runs along the beam, +Y is world up, +Z points out of the beam's face
//  toward the viewer. Everything virtual is a child of this, so relative alignment is
//  exact by construction and only ONE orientation has to be right.
//
//  GRAVITY IS TRUSTED. ARKit's world Y is accurate to a fraction of a degree and the
//  crane stands upright on a table, so the gear axes are horizontal by construction
//  and any vertical component in a measured facing direction can only be error. That
//  is what reduces the frame's whole rotation to a single number — `heading`.
//

import simd

struct CraneFrame: Equatable, Sendable {

    /// Midpoint between the two gear centres, on the plane.
    let origin: simd_float3

    /// Out of the beam's face, toward the viewer. Always horizontal.
    let normal: simd_float3

    /// Along the beam. Chosen so that `right x up == normal`.
    let right: simd_float3

    /// Exactly world up: `normal` is gravity-constrained horizontal, so the beam's
    /// vertical axis and the world's cannot disagree.
    var up: simd_float3 { simd_float3(0, 1, 0) }

    /// Compass direction of `normal`. The frame's only rotational degree of freedom,
    /// which is why smoothing is done on this single angle rather than on a matrix.
    var heading: Float { atan2(normal.x, normal.z) }

    /// Frame-local -> world. Used as the transform of the single `ARAnchor` that
    /// carries the whole scene.
    var transform: simd_float4x4 {
        simd_float4x4(
            simd_float4(right, 0),
            simd_float4(up, 0),
            simd_float4(normal, 0),
            simd_float4(origin, 1)
        )
    }

    /// World -> frame-local. The basis is orthonormal, so projection is the inverse.
    func localPoint(_ world: simd_float3) -> simd_float3 {
        let delta = world - origin
        return simd_float3(
            simd_dot(delta, right),
            simd_dot(delta, up),
            simd_dot(delta, normal)
        )
    }

    /// Builds a frame from the one angle and one point that define it.
    static func make(origin: simd_float3, heading: Float) -> CraneFrame {
        let normal = simd_float3(sin(heading), 0, cos(heading))
        return CraneFrame(origin: origin, normal: normal)
    }

    /// The `right` axis is fully determined by the normal, so it is never passed in.
    init(origin: simd_float3, normal: simd_float3) {
        self.origin = origin
        self.normal = normal
        self.right = simd_normalize(simd_cross(simd_float3(0, 1, 0), normal))
    }
}
