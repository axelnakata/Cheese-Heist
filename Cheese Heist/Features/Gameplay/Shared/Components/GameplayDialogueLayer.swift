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

import SwiftUI

struct GameplayDialogueLayer: View {

    let text: AttributedString
    var style: SpeechBubbleStyle = .parchment
    let isRevealComplete: Bool
    let onRevealComplete: () -> Void

    @Environment(\.layoutScale) private var scale
    @State private var revealFlag = false

    var body: some View {
        VStack {
            HStack {
                Spacer()
                bubble
            }
            .padding(.top, AppSpacing.xl * scale)
            Spacer()
        }
        .padding(.horizontal, AppSpacing.xl * scale)
        .allowsHitTesting(false)
    }

    private var bubble: some View {
        VStack(alignment: .trailing, spacing: AppSpacing.s * scale) {
            SpeechBubbleView(
                text: text,
                style: style,
                isRevealComplete: $revealFlag
            )

            if revealFlag {
                TapToContinueHint()
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
}

#Preview {
    GameplayDialogueLayer(
        text: PreviewDialogue.craneCompliment,
        isRevealComplete: true,
        onRevealComplete: {}
    )
    .previewBackdrop(.cameraFeed)
}
