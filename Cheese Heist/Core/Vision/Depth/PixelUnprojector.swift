//
//  PixelUnprojector.swift
//  Cheese Heist
//
//  Pixel + depth -> world point.
//

import simd
import CoreGraphics

enum PixelUnprojector {

    /// The world point on the ray through `pixel`, at `depth` along the optical axis.
    ///
    /// The intrinsics are used UNSCALED here, unlike anywhere that walks the depth
    /// buffer: `pixel` is a full-resolution capture-image coordinate, which is the
    /// space the intrinsics are already expressed in.
    static func unproject(
        pixel: CGPoint, depth: Float, captured: CapturedFrameData
    ) -> simd_float3 {
        let intrinsics = captured.cameraIntrinsics
        let fx = intrinsics.columns.0.x
        let fy = intrinsics.columns.1.y
        let cx = intrinsics.columns.2.x
        let cy = intrinsics.columns.2.y

        let x = (Float(pixel.x) - cx) * depth / fx
        let y = (Float(pixel.y) - cy) * depth / fy

        // Camera convention: +X right, +Y up, -Z forward. The image's y grows
        // downward, hence the flip.
        let world = captured.cameraTransform * simd_float4(x, -y, -depth, 1)
        return simd_float3(world.x, world.y, world.z)
    }
}
