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
        /// `Level1HUDLayer.Metric.cornerInset` plus half the joystick, so the hole and
        /// the demonstration both land on where the control is.
        static let joystickInset: CGFloat = 164
        /// The control's own size — what the demo has to match.
        static let joystickDiameter: CGFloat = 200
        /// …and the hole, which is deliberately a little wider than the control.
        static let joystickRadius: CGFloat = 130

        /// ═══ THE HOLE IS SIZED OFF THE GEAR, AND THE GEAR IS 10mm OR 42mm. ═══
        ///
        /// It was `radius × 1.9 + 28pt` for the driver and `× 2.2` for the follower,
        /// which on a 40T cut a hole five times the gear across — wide enough to take in
        /// the 8T meshed 24mm away, so "look at THIS gear" lit up both of them and
        /// singled out neither. A snug 1.3 plus a small constant lands just outside the
        /// teeth on the big gear and stays legible on the small one.
        static let holeGrowth: CGFloat = 1.3
        static let holePadding: CGFloat = 12
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
                    CircularDragHint(diameter: Metric.joystickDiameter * scale)
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

        case .followerGearAndRope:
            return gearHole(role: .follower)
        }
    }

    private func gearHole(role: GearRole) -> SpotlightTarget? {
        guard let target = targets.first(where: { $0.role == role }) else { return nil }
        return SpotlightTarget(center: target.center, radius: radius(around: target))
    }

    /// Just proud of this gear's own teeth, and never as far as the other gear's centre.
    ///
    /// The clamp is the part that matters on an 8T/40T pair: they MESH, so their rims
    /// touch and no hole can take in one rim without grazing the other. What it can do
    /// is stop short of the other gear's middle, which is the difference between a
    /// spotlight that points at a gear and one that contains both of them.
    private func radius(around target: GearScreenTarget) -> CGFloat {
        let snug = target.radius * Metric.holeGrowth + Metric.holePadding * scale
        guard let other = targets.first(where: { $0.id != target.id }) else { return snug }

        let gap = hypot(other.center.x - target.center.x, other.center.y - target.center.y)
        return min(snug, max(target.radius, gap))
    }

    private func joystickCentre(in size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width - Metric.joystickInset * scale,
            y: size.height - Metric.joystickInset * scale
        )
    }
}
