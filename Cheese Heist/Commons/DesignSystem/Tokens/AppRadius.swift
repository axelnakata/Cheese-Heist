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
    static let bubble: CGFloat = 42.5
    /// Buttons — larger than half the 78.14 pt button height, so it reads as a capsule.
    static let pill: CGFloat = 63.57
}
