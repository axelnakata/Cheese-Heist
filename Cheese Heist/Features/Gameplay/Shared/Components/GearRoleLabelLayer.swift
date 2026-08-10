//
//  GearRoleLabelLayer.swift
//  Cheese Heist
//
//  The "Driver" and "Follower" pills, each on a leader line back to the gear it names.
//
//  Positions come from `GearScreenTarget`, which is re-projected every frame, so the
//  labels track the real gears as the child moves rather than sitting at fixed screen
//  positions that happen to line up from one angle.
//
//  The pills sit BELOW their gears with an elbow leader line, as drawn in the role
//  selection frame: the crane's beam is above the gears and a label placed there would
//  cover the mouse.
//

import SwiftUI

struct GearRoleLabelLayer: View {

    let targets: [GearScreenTarget]

    @Environment(\.layoutScale) private var scale

    /// How far below the gear the pill hangs, before scaling.
    private enum Metric {
        static let drop: CGFloat = 96
        static let sidestep: CGFloat = 54
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(targets) { target in
                let anchor = pillAnchor(for: target)

                LeaderLineShape(from: leaderStart(for: target), to: anchor)
                    .stroke(colour(for: target.role), lineWidth: AppStroke.chip * scale)

                GearRoleLabel(role: target.role)
                    .position(anchor)
            }
        }
        .allowsHitTesting(false)
    }

    /// The line leaves the gear's rim, not its centre, so it never draws across the
    /// twin it is pointing at.
    private func leaderStart(for target: GearScreenTarget) -> CGPoint {
        CGPoint(x: target.center.x, y: target.center.y + target.radius)
    }

    /// Driver hangs to the left, follower to the right, so the two pills cannot
    /// collide when the gears are close together on screen.
    private func pillAnchor(for target: GearScreenTarget) -> CGPoint {
        let sidestep = Metric.sidestep * scale * (target.role == .driver ? -1 : 1)
        return CGPoint(
            x: target.center.x + sidestep,
            y: target.center.y + target.radius + Metric.drop * scale
        )
    }

    private func colour(for role: GearRole) -> Color {
        role == .driver ? AppColor.roleDriver : AppColor.roleFollower
    }
}
