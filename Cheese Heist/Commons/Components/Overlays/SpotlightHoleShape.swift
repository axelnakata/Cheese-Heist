// SpotlightHoleShape.swift — Cheese Heist
// A rectangle with a rounded-rect hole cut out of it.

import SwiftUI

struct SpotlightHoleShape: Shape {

    var target: SpotlightTarget

    var animatableData: AnimatablePair<
        AnimatablePair<CGFloat, CGFloat>,
        AnimatablePair<CGFloat, CGFloat>
    > {
        get {
            AnimatablePair(
                AnimatablePair(target.center.x, target.center.y),
                AnimatablePair(target.size.width, target.size.height)
            )
        }
        set {
            target = SpotlightTarget(
                center: CGPoint(x: newValue.first.first, y: newValue.first.second),
                size: CGSize(width: newValue.second.first, height: newValue.second.second),
                cornerRadius: target.cornerRadius
            )
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        let hole = CGRect(
            x: target.center.x - target.size.width / 2,
            y: target.center.y - target.size.height / 2,
            width: target.size.width,
            height: target.size.height
        )
        let rounded = Path(
            roundedRect: hole,
            cornerRadius: target.cornerRadius,
            style: .continuous
        )
        path.addPath(rounded)
        return path
    }
}
