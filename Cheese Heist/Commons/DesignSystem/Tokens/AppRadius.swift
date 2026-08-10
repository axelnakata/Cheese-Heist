//
//  AppRadius.swift
//  Cheese Heist
//
//  PRD §7.5 — corner radii, in design-scale points.
//

import CoreGraphics

enum AppRadius {
    /// Instruction chip.
    static let chip: CGFloat = 30
    /// Speech bubble.
    ///
    /// Measured off the rendered Level 1 frames, not taken as half the height: the
    /// bubble's edge profile fits a 30pt corner to within a pixel at every row, and
    /// 42.5 (half of the 85pt single-line height) drew a capsule the design is not.
    static let bubble: CGFloat = 30
    /// Buttons — larger than half the 78.14 pt button height, so it reads as a capsule.
    static let pill: CGFloat = 63.57
}
