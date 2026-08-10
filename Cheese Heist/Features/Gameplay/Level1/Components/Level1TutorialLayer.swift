//
//  Level1TutorialLayer.swift
//  Cheese Heist
//
//  The teaching beats: the spotlight cut around whatever is being named, the mouse's
//  speech bubble, and the circular drag hint over the joystick.
//
//  The spotlight hole is derived from a LIVE projection, not from a constant. The gears
//  move on screen whenever the child moves, and a hole cut at a fixed position would
//  drift off the gear it is supposed to be pointing at within a second.
//

import SwiftUI

struct Level1TutorialLayer: View {

    let subject: SpotlightSubject
    let targets: [GearScreenTarget]
    let beat: DialogueBeat?
    let isRevealComplete: Bool

    /// The mouse's head on screen — the bubble hangs off it.
    let mouseAnchor: CGPoint?

    let onRevealComplete: () -> Void

    @Environment(\.layoutScale) private var scale

    /// Matches `Level1HUDLayer.Metric.cornerInset` plus half the joystick, so the hole
    /// lands on the control rather than beside it.
    private enum Metric {
        static let joystickInset: CGFloat = 164
        static let joystickRadius: CGFloat = 130
        static let holePadding: CGFloat = 28
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let hole = hole(in: proxy.size) {
                    SpotlightOverlay(target: hole)
                        .transition(.opacity)
                }

                if let beat {
                    GameplayDialogueLayer(
                        text: DialogueBeatText.attributed(beat),
                        isRevealComplete: isRevealComplete,
                        anchor: mouseAnchor,
                        onRevealComplete: onRevealComplete
                    )
                }

                if subject == .joystick {
                    CircularDragHint()
                        .position(joystickCentre(in: proxy.size))
                        .allowsHitTesting(false)
                }
            }
        }
    }

    /// Where to cut the hole for the current subject, or nil for no spotlight.
    private func hole(in size: CGSize) -> SpotlightTarget? {
        switch subject {
        case .none:
            return nil

        case .joystick:
            return SpotlightTarget(
                center: joystickCentre(in: size),
                radius: Metric.joystickRadius * scale
            )

        case .driverGear:
            return gearHole(role: .driver)

        // One hole covering the follower and the rope it winds: the rope hangs below
        // the gear, so the circle is grown downward rather than a second hole cut.
        case .followerGearAndRope:
            return gearHole(role: .follower, growth: 2.2)
        }
    }

    private func gearHole(role: GearRole, growth: CGFloat = 1.9) -> SpotlightTarget? {
        guard let target = targets.first(where: { $0.role == role }) else { return nil }
        return SpotlightTarget(
            center: target.center,
            radius: target.radius * growth + Metric.holePadding * scale
        )
    }

    private func joystickCentre(in size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width - Metric.joystickInset * scale,
            y: size.height - Metric.joystickInset * scale
        )
    }
}
