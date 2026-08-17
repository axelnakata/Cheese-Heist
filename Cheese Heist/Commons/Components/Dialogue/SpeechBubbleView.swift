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

    static var tailHeight: CGFloat { Metric.tailSize.height }
    static var minimumHeight: CGFloat { Metric.minHeight }
    static var maximumTextWidth: CGFloat { Metric.maxWidth }

    fileprivate enum Metric {
        static let minHeight: CGFloat = 64
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 20
        static let tailSize = CGSize(width: 28, height: 32)
        static let maxWidth: CGFloat = 560
        static let cornerRadius: CGFloat = 32
        static let shadowDepth: CGFloat = 10
    }

    let text: AttributedString
    var charactersPerSecond: Double = 40
    var style: SpeechBubbleStyle = .parchment

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
            .frame(minHeight: Metric.minHeight * scale, alignment: .center)
            .padding(.leading, Metric.tailSize.width * scale)
            .background(background)
    }

    private var label: some View {
        TypewriterText(
            text: text,
            charactersPerSecond: charactersPerSecond,
            isComplete: $isRevealComplete
        )
        .appText(AppFont.dialogue)
        .foregroundStyle(style.textColor)
        .frame(width: textWidth, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var textWidth: CGFloat {
        DialogueTextWidth.measure(
            text, style: AppFont.dialogue, cap: Metric.maxWidth
        ) * scale
    }

    private var background: some View {
        GeometryReader { geo in
            let tailWidth = Metric.tailSize.width * scale
            let bodyWidth = max(0, geo.size.width - tailWidth)

            ZStack {
                RoundedRectangle(cornerRadius: Metric.cornerRadius * scale, style: .continuous)
                    .fill(AppColor.bubbleDarkParchment)
                    .frame(width: bodyWidth, height: geo.size.height)
                    .offset(
                        x: tailWidth - (20 * scale),
                        y: Metric.shadowDepth * scale
                    )

                bubbleShape
                    .fill(style.fillColor)
            }
        }
    }

    private var bubbleShape: SpeechBubbleShape {
        SpeechBubbleShape(
            cornerRadius: Metric.cornerRadius * scale,
            tailSize: CGSize(
                width: Metric.tailSize.width * scale,
                height: Metric.tailSize.height * scale
            )
        )
    }
}
