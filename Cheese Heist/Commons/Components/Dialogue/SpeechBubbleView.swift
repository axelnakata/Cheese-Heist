//
//  SpeechBubbleView.swift
//  Cheese Heist
//
//  PRD §7.6 — Figma 639:126. Height 85, radius .bubble, width hugs, accent fill,
//  tail bottom-left, .dialogue text, 30 pt padding.
//

import SwiftUI

struct SpeechBubbleView: View {

    private enum Metric {
        static let minHeight: CGFloat = 85
        static let horizontalPadding: CGFloat = 30
        static let verticalPadding: CGFloat = 30
        static let tailSize = CGSize(width: 34, height: 24)
        static let maxWidth: CGFloat = 620
    }

    let text: AttributedString
    var charactersPerSecond: Double = 40

    /// `true` finishes the reveal at once; the bubble sets it when the line ends.
    /// Defaults to a constant `true` for static callers that want no typewriter.
    @Binding var isRevealComplete: Bool

    @Environment(\.layoutScale) private var scale

    init(
        text: AttributedString,
        charactersPerSecond: Double = 40,
        isRevealComplete: Binding<Bool> = .constant(true)
    ) {
        self.text = text
        self.charactersPerSecond = charactersPerSecond
        self._isRevealComplete = isRevealComplete
    }

    var body: some View {
        TypewriterText(
            text: text,
            charactersPerSecond: charactersPerSecond,
            isComplete: $isRevealComplete
        )
        .appText(AppFont.dialogue)
        .foregroundStyle(AppColor.textPrimary)
        .frame(maxWidth: Metric.maxWidth * scale, alignment: .leading)
        .padding(.horizontal, Metric.horizontalPadding * scale)
        .padding(.vertical, Metric.verticalPadding * scale)
        .frame(minHeight: Metric.minHeight * scale, alignment: .leading)
        .padding(.bottom, Metric.tailSize.height * scale)
        .background(bubbleShape.fill(AppColor.accent))
    }

    private var bubbleShape: SpeechBubbleShape {
        SpeechBubbleShape(
            cornerRadius: AppRadius.bubble * scale,
            tailSize: CGSize(
                width: Metric.tailSize.width * scale,
                height: Metric.tailSize.height * scale
            )
        )
    }
}

#Preview("Reveal — camera feed") {
    @Previewable @State var isComplete = false

    SpeechBubbleView(text: PreviewDialogue.hungryMouse, isRevealComplete: $isComplete)
        .onTapGesture { isComplete = true }
        .previewBackdrop(.cameraFeed)
}

#Preview("Static + bold span — parchment") {
    VStack(alignment: .leading, spacing: AppSpacing.l) {
        SpeechBubbleView(text: PreviewDialogue.craneCompliment)
        SpeechBubbleView(text: PreviewDialogue.buildACrane)
    }
    .previewBackdrop(.parchment)
}
