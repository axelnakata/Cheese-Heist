//
//  GearDepthSample.swift
//  Cheese Heist
//

import simd

/// One gear's distance, measured off LiDAR.
struct GearDepthSample: Sendable, Equatable {

    /// The gear's centre, unprojected at the measured depth.
    ///
    /// On the ray through the detected centre pixel by construction, so it reprojects
    /// to that pixel exactly — the property the whole overlay leans on.
    let world: simd_float3

    /// Perpendicular distance from the camera plane, in metres. ARKit's depth maps are
    /// along the optical axis, not radial, which is why this is not `simd_length`.
    let depth: Float

    /// Confident depth pixels behind the reading. Small gears at range give few, and
    /// the caller uses this to decide which gear to believe.
    let sampleCount: Int
}
