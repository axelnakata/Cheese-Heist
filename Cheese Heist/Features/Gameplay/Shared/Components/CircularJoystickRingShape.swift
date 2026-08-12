// CircularJoystickRingShape.swift — Cheese Heist
// Ring path for the circular drag joystick control.

import SwiftUI

struct CircularJoystickRingShape: Shape {
    let lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(360),
            clockwise: false
        )
        return path
    }
}
