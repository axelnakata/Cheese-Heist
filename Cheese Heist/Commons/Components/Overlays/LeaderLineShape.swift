//
//  LeaderLineShape.swift
//  Cheese Heist
//
//  Connects a role label to the gear it names.
//
//  An elbow, not a diagonal: the label frames draw the line dropping straight down from
//  the gear and then turning once toward the pill. A diagonal across a busy AR scene
//  reads as part of the scene; a right-angled line reads as annotation.
//

import SwiftUI

struct LeaderLineShape: Shape {
    let from: CGPoint
    let to: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        // Down first, across second. The corner sits at the label's height so the
        // horizontal run arrives at the pill rather than at its top edge.
        path.addLine(to: CGPoint(x: from.x, y: to.y))
        path.addLine(to: to)
        return path
    }
}

#Preview {
    LeaderLineShape(
        from: CGPoint(x: 120, y: 80),
        to: CGPoint(x: 220, y: 200)
    )
    .stroke(AppColor.roleDriver, lineWidth: AppStroke.chip)
    .frame(width: 320, height: 260)
    .previewBackdrop(.cameraFeed)
}
