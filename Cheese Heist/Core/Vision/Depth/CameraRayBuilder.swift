//
//  CameraRayBuilder.swift
//  Cheese Heist
//
//  The world-space ray through a pixel. This is the backbone of the overlay's
//  alignment: a point placed on the ray through a pixel projects back to that pixel
//  by construction, so a gear placed this way lands on the real gear whatever angle
//  it is seen from.
//

import simd
import CoreGraphics

/// A ray in world space.
struct CameraRay: Equatable, Sendable {
    let origin: simd_float3
    /// Unit length.
    let direction: simd_float3
}

enum CameraRayBuilder {

    static func ray(
        throughPixel pixel: CGPoint,
        intrinsics: simd_float3x3,
        cameraTransform: simd_float4x4
    ) -> CameraRay {
        let fx = intrinsics.columns.0.x
        let fy = intrinsics.columns.1.y
        let cx = intrinsics.columns.2.x
        let cy = intrinsics.columns.2.y

        // Same convention as `PixelUnprojector`: +X right, +Y up, -Z forward.
        let cameraSpace = simd_float3(
            (Float(pixel.x) - cx) / fx,
            -(Float(pixel.y) - cy) / fy,
            -1
        )

        let rotation = simd_float3x3(
            simd_float3(cameraTransform.columns.0.x,
                        cameraTransform.columns.0.y,
                        cameraTransform.columns.0.z),
            simd_float3(cameraTransform.columns.1.x,
                        cameraTransform.columns.1.y,
                        cameraTransform.columns.1.z),
            simd_float3(cameraTransform.columns.2.x,
                        cameraTransform.columns.2.y,
                        cameraTransform.columns.2.z)
        )

        return CameraRay(
            origin: cameraTransform.translationVector,
            direction: simd_normalize(rotation * cameraSpace)
        )
    }

    static func ray(throughPixel pixel: CGPoint, captured: CapturedFrameData) -> CameraRay {
        ray(
            throughPixel: pixel,
            intrinsics: captured.cameraIntrinsics,
            cameraTransform: captured.cameraTransform
        )
    }
}
