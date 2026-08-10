//
//  ApparentSizeCheck.swift
//  Cheese Heist
//
//  A second opinion on distance that shares no assumptions with LiDAR at all.
//
//  A 40T gear is 42mm across the tips, so how wide its box is on screen says how far
//  away it is whatever the depth map reports. This is here to catch a probe that
//  locked onto a hand in the foreground or a wall behind — not to shave millimetres,
//  which is why the bounds are wide.
//

import CoreGraphics
import simd

enum ApparentSizeCheck {

    /// Bounds on (range implied by the gear's size on screen) / (range measured).
    static let minimumAgreement: Float = 0.55
    static let maximumAgreement: Float = 1.8

    /// A box narrower than this is too few pixels to say anything.
    static let minimumBoxPixels: Float = 4

    /// Whether the measured range survives the gear's own apparent size.
    ///
    /// Returns true when the check cannot be run at all — a box too small to read, or
    /// intrinsics that make no sense. An unavailable check must not reject a
    /// measurement that nothing has actually contradicted.
    static func accepts(
        measuredRange: Float,
        largestGearTeeth: Int,
        box: CGRect,
        intrinsics: simd_float3x3
    ) -> Bool {
        guard let implied = impliedRange(
            teeth: largestGearTeeth, box: box, intrinsics: intrinsics
        ), measuredRange > 0 else { return true }

        let agreement = implied / measuredRange
        return agreement > minimumAgreement && agreement < maximumAgreement
    }

    /// How far away the gear must be for its tips to subtend this box, in metres.
    static func impliedRange(
        teeth: Int, box: CGRect, intrinsics: simd_float3x3
    ) -> Float? {
        // Module 1: tip diameter in millimetres is the tooth count plus two.
        let tipDiameter = Float(teeth + 2) * 0.001
        let apparent = Float(max(box.width, box.height))
        let focalLength = intrinsics.columns.0.x

        guard apparent > minimumBoxPixels, focalLength > 1 else { return nil }
        return tipDiameter * focalLength / apparent
    }
}
