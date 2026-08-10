//
//  LayoutScale.swift
//  Cheese Heist
//
//  PRD §7.4 — every Figma frame is 1366 × 1024 pt (iPad Pro 12.9"). On an 11" iPad
//  (1194 × 834) every design-scale value must shrink by the same factor.
//
//  No view computes its own scale. It is read once from the environment.
//

import CoreGraphics

enum LayoutScale {

    /// Width of every Figma frame, in points.
    static let designWidth: CGFloat = 1366
    /// Height of every Figma frame, in points.
    static let designHeight: CGFloat = 1024

    /// Neutral factor, used by previews and by any container of unknown width.
    static let identity: CGFloat = 1

    /// `containerWidth / 1366`, clamped so a zero-width layout pass — which SwiftUI
    /// does hand out on the first frame — cannot collapse the whole UI to nothing.
    static func factor(forWidth containerWidth: CGFloat) -> CGFloat {
        guard containerWidth > 0 else { return identity }
        return containerWidth / designWidth
    }
}
