//
//  SpeechBubbleView.swift
//  Cheese Heist
//
//  PRD §7.6 — Figma 431:88. Parchment fill, 30pt corner, curved tail bottom-left,
//  .dialogue text, 30pt padding, soft drop shadow.
//
//  ═══ IT HUGS ITS TEXT. ═══
//
//  It used to carry `.frame(maxWidth: 620)` between the text and the background, which
//  is the opposite of hugging: a `maxWidth` frame reports the width it was PROPOSED,
//  clamped — so offered a full-width parent it returned 620 every time and a five-word
//  line got a bubble sized for twenty. The width now comes from `DialogueTextWidth`,
//  which measures the sentence; see that file for why SwiftUI cannot express this on
//  its own. `SpeechBubbleLayoutTests` renders four lengths and compares them.
//

import SwiftUI

struct SpeechBubbleView: View {

    /// How far the tail hangs below the body. Published so a caller placing the bubble
    /// can ask `SpeechBubbleShape` where its point ends up.
    static var tailHeight: CGFloat { Metric.tailSize.height }

    /// The body's minimum height, and the widest the text is allowed to run before it
    /// wraps. Published for the layout tests, which would otherwise restate them.
    static var minimumHeight: CGFloat { Metric.minHeight }
    static var maximumTextWidth: CGFloat { Metric.maxWidth }

    fileprivate enum Metric {
        static let minHeight: CGFloat = 84
        static let horizontalPadding: CGFloat = 30
        static let verticalPadding: CGFloat = 26
        /// Width is how far along the bottom edge the tail's root reaches; height is how
        /// far it protrudes below the body, and so how much room the layout reserves.
        static let tailSize = CGSize(width: 46, height: 12)
        static let maxWidth: CGFloat = 560
        static let shadowRadius: CGFloat = 10
        static let shadowOffset: CGFloat = 4
    }

    let text: AttributedString
    var charactersPerSecond: Double = 40
    var style: SpeechBubbleStyle = .parchment

    /// `true` finishes the reveal at once; the bubble sets it when the line ends.
    /// Defaults to a constant `true` for static callers that want no typewriter.
    @Binding var isRevealComplete: Bool

    @Environment(\.layoutScale) private var scale

    init(
        text: AttributedString,
        charactersPerSecond: Double = 40,
        style: SpeechBubbleStyle = .parchment,
        isRevealComplete: Binding<Bool> = .constant(true)
    ) {
        self.text = text
        self.charactersPerSecond = charactersPerSecond
        self.style = style
        self._isRevealComplete = isRevealComplete
    }

    var body: some View {
        label
            .padding(.horizontal, Metric.horizontalPadding * scale)
            .padding(.vertical, Metric.verticalPadding * scale)
            .frame(minHeight: Metric.minHeight * scale, alignment: .leading)
            .padding(.bottom, Metric.tailSize.height * scale)
            // Room on the leading edge for the tail's horn, which reaches out past the
            // body. The shape insets its body to match, so the text stays where it is
            // relative to the bubble rather than shifting right.
            .padding(.leading, SpeechBubbleShape.bulge(forTailHeight: Metric.tailSize.height) * scale)
            .background(background)
    }

    /// The text, sized to itself and capped — see the note at the top of the file.
    private var label: some View {
        let typewriter = TypewriterText(
            text: text,
            charactersPerSecond: charactersPerSecond,
            isComplete: $isRevealComplete
        )

        return typewriter
            .appText(AppFont.dialogue)
            .foregroundStyle(style.textColor)
            .frame(width: textWidth, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Measured, not proposed — see `DialogueTextWidth`.
    private var textWidth: CGFloat {
        DialogueTextWidth.measure(
            text, style: AppFont.dialogue, cap: Metric.maxWidth
        ) * scale
    }

    private var background: some View {
        bubbleShape
            .fill(style.fillColor)
            .shadow(
                color: AppColor.bubbleShadow,
                radius: Metric.shadowRadius * scale,
                y: Metric.shadowOffset * scale
            )
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

#Preview("Hugs short and long alike") {
    VStack(alignment: .leading, spacing: AppSpacing.l) {
        SpeechBubbleView(text: AttributedString("Wow!"))
        SpeechBubbleView(text: PreviewDialogue.craneCompliment)
        SpeechBubbleView(text: PreviewDialogue.buildACrane)
    }
    .previewBackdrop(.cameraFeed)
}
