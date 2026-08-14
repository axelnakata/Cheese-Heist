//
//  GameplayDialogueLayer.swift
//  Cheese Heist
//
//  The mouse's speech bubble, with its typewriter and its tap-to-continue hint.
//
//  The bubble owns the reveal and reports it upward; `DialogueSequencer` owns which
//  beat is showing. That split is what makes a tap during the reveal COMPLETE the line
//  instead of skipping it — the sequencer sees `isRevealComplete == false` and consumes
//  the tap itself.
//
//  ═══ IT HANGS OFF THE MOUSE, NOT OFF THE CORNER. ═══
//
//  The bubble used to be pinned to the top-right of the screen, which is fine in a
//  mockup where the mouse is always in the same place and wrong the moment the child
//  walks round the crane: the mouse would leave the frame entirely and its words would
//  stay behind, floating in a corner with a tail pointing at nothing.
//
//  So the tail is placed at the mouse's projected head and the body hangs up and to the
//  right of it, which is the arrangement in every Level 1 frame.
//
//  WHEN THE MOUSE LEAVES THE SCREEN THE BUBBLE IS CLAMPED, NOT HIDDEN. Hiding it would
//  be the more literal reading of "attached", and it would mean a child who tilts too
//  far loses the sentence the lesson is made of — with no way to get it back except to
//  find the mouse again. Clamped, the bubble slides to the edge the mouse went out of
//  and stays readable, and the tail keeps pointing the way back.
//

import SwiftUI

struct GameplayDialogueLayer: View {

    let text: AttributedString
    var style: SpeechBubbleStyle = .parchment
    let isRevealComplete: Bool

    /// The mouse's head in screen coordinates, or nil before the scene exists.
    let anchor: CGPoint?

    let onRevealComplete: () -> Void

    /// False when nothing in this phase advances on a tap — Level 1's post-pick beat
    /// sits until the joystick turns, not until it is tapped, and the hint would be a
    /// promise the bubble does not keep.
    var showsContinueHint: Bool = true

    @Environment(\.layoutScale) private var scale
    @State private var revealFlag = false
    @State private var bubbleSize: CGSize = .zero

    private enum Metric {
        /// Gap between the tail's tip and the mouse's head.
        static let tailClearance: CGFloat = 10
        /// Keeps the bubble off the very edge when it is clamped.
        static let screenMargin: CGFloat = 24
        /// Where the bubble sits before the scene has ever been projected.
        static let fallbackAnchor = CGPoint(x: 0.62, y: 0.42)
    }

    var body: some View {
        GeometryReader { proxy in
            bubble
                .background(sizeReader)
                .position(origin(in: proxy.size))
        }
        .allowsHitTesting(false)
    }

    /// The hint is an OVERLAY, not a stacked sibling. In a `VStack` it counted toward
    /// the measured height, and the placement below works back from the bubble's bottom
    /// edge — so every bubble floated a hint's worth too high and its tail stopped short
    /// of the mouse.
    private var bubble: some View {
        SpeechBubbleView(text: text, style: style, isRevealComplete: $revealFlag)
            .overlay(alignment: .bottomTrailing) {
                if revealFlag && showsContinueHint {
                    TapToContinueHint(title: "tap to continue..")
                        .offset(y: (AppFont.body.lineHeight + AppSpacing.xs) * scale)
                        .transition(.opacity)
                }
            }
            .onChange(of: revealFlag) { _, complete in
                if complete { onRevealComplete() }
            }
        // A new beat resets the typewriter; without this the second bubble in a run
        // appears fully revealed because the flag is still true from the first.
        .onChange(of: text) { _, _ in revealFlag = false }
        .task(id: text) { revealFlag = isRevealComplete }
    }

    private var sizeReader: some View {
        GeometryReader { proxy in
            Color.clear.onChange(of: proxy.size, initial: true) { _, size in
                bubbleSize = size
            }
        }
    }

    /// The bubble's CENTRE, which is what `.position` wants — worked back from where
    /// the tail's tip has to land, then clamped into the screen.
    private func origin(in screen: CGSize) -> CGPoint {
        let target = anchor ?? CGPoint(
            x: screen.width * Metric.fallbackAnchor.x,
            y: screen.height * Metric.fallbackAnchor.y
        )

        // The tail's point is what aims at the mouse, and it sits a fixed distance in
        // from the bubble's own leading edge — so that distance comes back out here
        // rather than being guessed at.
        let tip = SpeechBubbleShape.tipOffset(forTailHeight: SpeechBubbleView.tailHeight) * scale
        let half = CGSize(width: bubbleSize.width / 2, height: bubbleSize.height / 2)
        let centre = CGPoint(
            x: target.x - tip + half.width,
            y: target.y - Metric.tailClearance * scale - half.height
        )

        let margin: CGFloat = Metric.screenMargin * scale
        let minX: CGFloat = half.width + margin
        let maxX: CGFloat = max(minX, screen.width - half.width - margin)
        let minY: CGFloat = half.height + margin
        let maxY: CGFloat = max(minY, screen.height - half.height - margin)

        return CGPoint(
            x: centre.x.clamped(to: minX...maxX),
            y: centre.y.clamped(to: minY...maxY)
        )
    }
}

#Preview("Anchored to a mouse mid-screen") {
    GameplayDialogueLayer(
        text: PreviewDialogue.craneCompliment,
        isRevealComplete: true,
        anchor: CGPoint(x: 420, y: 560),
        onRevealComplete: {}
    )
    .previewBackdrop(.cameraFeed)
}

#Preview("Short line — the bubble hugs it") {
    GameplayDialogueLayer(
        text: AttributedString("Wow!"),
        isRevealComplete: true,
        anchor: CGPoint(x: 300, y: 400),
        onRevealComplete: {}
    )
    .previewBackdrop(.cameraFeed)
}
