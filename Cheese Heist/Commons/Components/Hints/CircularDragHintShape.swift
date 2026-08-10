// CircularDragHintShape.swift — Cheese Heist
// Animated circular arrow path for the crank tutorial.

import SwiftUI

struct CircularDragHintShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.35
        let startAngle = Angle.degrees(-90)
        let endAngle = Angle.degrees(-90 + 300 * Double(progress))

        var path = Path()
        path.addArc(
            center: center, radius: radius,
            startAngle: startAngle, endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}
