// SpotlightTarget.swift — Cheese Heist
// Model: position + size for a spotlight hole in a scrim.

import CoreGraphics

struct SpotlightTarget: Equatable, Sendable {
    let center: CGPoint
    let size: CGSize
    let cornerRadius: CGFloat

    static let zero = SpotlightTarget(
        center: .zero, size: .zero, cornerRadius: 0
    )

    /// A circular hole. Gears and the joystick are round, so this is the shape the
    /// teaching spotlight almost always wants.
    init(center: CGPoint, radius: CGFloat) {
        self.center = center
        self.size = CGSize(width: radius * 2, height: radius * 2)
        self.cornerRadius = radius
    }

    init(center: CGPoint, size: CGSize, cornerRadius: CGFloat) {
        self.center = center
        self.size = size
        self.cornerRadius = cornerRadius
    }
}
