//
//  Level1TutorialLayer.swift
//  Cheese Heist
//
//  The teaching beats: the mouse's speech bubble, and the circular drag hint over the
//  joystick once a driver has been picked.
//
//  NO SCRIM. A spotlight hole used to sit behind the hint, dimming the rest of the
//  camera feed to point at the joystick — on a real classroom photo that read as a
//  jarring black cutout, not an annotation. Level 2 never had one, and the hint ring's
//  own animation is enough on its own to say "this turns".
//

import SwiftUI

struct Level1TutorialLayer: View {

    let showsJoystickHint: Bool
    let beat: DialogueBeat?
    let isRevealComplete: Bool

    /// The mouse's head on screen — the bubble hangs off it.
    let mouseAnchor: CGPoint?

    let onRevealComplete: () -> Void

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        /// Matches `Level1HUDLayer.Metric.cornerInset` plus half the joystick, so the
        /// demonstration lands on where the control is.
        static let joystickInset: CGFloat = 164
        /// The control's own size — what the demo has to match.
        static let joystickDiameter: CGFloat = 200
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let beat {
                    GameplayDialogueLayer(
                        text: DialogueBeatText.attributed(beat),
                        isRevealComplete: isRevealComplete,
                        anchor: mouseAnchor,
                        onRevealComplete: onRevealComplete,
                        showsContinueHint: false
                    )
                }

                if showsJoystickHint {
                    CircularDragHint(diameter: Metric.joystickDiameter * scale)
                        .position(joystickCentre(in: proxy.size))
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private func joystickCentre(in size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width - Metric.joystickInset * scale,
            y: size.height - Metric.joystickInset * scale
        )
    }
}
