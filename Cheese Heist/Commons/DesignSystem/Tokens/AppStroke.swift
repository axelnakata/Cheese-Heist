//
//  AppStroke.swift
//  Cheese Heist
//
//  PRD §7.5 — stroke widths, in design-scale points.
//

import CoreGraphics

enum AppStroke {
    static let button: CGFloat = 1.27
    static let chip: CGFloat = 1.50
    /// Ring of an on-camera control — the crank, and the hint that demonstrates it.
    /// Shared so the demo and the control it previews cannot drift apart.
    static let control: CGFloat = 5
}
