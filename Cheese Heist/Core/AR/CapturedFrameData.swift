// CapturedFrameData.swift — Cheese Heist
// Port from gear-poc: everything needed for 2D→3D unprojection from one ARFrame.

import ARKit

struct CapturedFrameData: Sendable {
    let cameraTransform: simd_float4x4
    let cameraIntrinsics: simd_float3x3
    let depthMap: CVPixelBuffer
    let confidenceMap: CVPixelBuffer?
    let imagePixelSize: CGSize
}
