//
//  GearDetection.swift
//  Cheese Heist
//
//  One gear found in one camera frame. Pixels only — no world position, no role,
//  no opinion about whether the detection is trustworthy.
//

import CoreGraphics
import Foundation

/// One gear found in a frame.
struct GearDetection: Sendable, Identifiable, Equatable {
    let id = UUID()
    let toothCount: Int
    let confidence: Float

    /// Bounding box in the ORIGINAL captured-image pixel space, not the square crop
    /// the model actually ran on. Callers unproject from this without ever needing to
    /// know the crop existed.
    let imageRect: CGRect

    var centerPixel: CGPoint {
        CGPoint(x: imageRect.midX, y: imageRect.midY)
    }

    static func == (lhs: GearDetection, rhs: GearDetection) -> Bool {
        lhs.id == rhs.id
    }
}
