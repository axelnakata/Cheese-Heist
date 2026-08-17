//
//  SpeechBubbleLayoutTests.swift
//  CheeseHeistTests
//
//  Does the bubble actually hug its text?
//
//  This is testable and worth testing because "dynamic width" is not a matter of taste
//  — it is a number, and the previous implementation got it wrong in a way that looked
//  deliberate: `.frame(maxWidth: 620)` returns the width it was PROPOSED rather than
//  the width the text wants, so every bubble came out the same size and the mistake
//  read as a design choice. `ImageRenderer` measures the laid-out view, so the
//  regression is one comparison away rather than a screenshot away.
//

import Foundation
import SwiftUI
import Testing
@testable import Cheese_Heist

@MainActor
struct SpeechBubbleLayoutTests {

    private static let short = AttributedString("Wow!")
    private static let medium = AttributedString("Wow! Great job on making this crane!")
    private static let long = AttributedString(
        "Now, choosing the driver and follower gear is very important, and it is the "
            + "whole reason this crane can lift anything at all."
    )

    private static func size(of text: AttributedString) -> CGSize {
        let renderer = ImageRenderer(content: SpeechBubbleView(text: text))
        return renderer.uiImage?.size ?? .zero
    }

    @Test("a short line makes a narrow bubble")
    func shortIsNarrowerThanMedium() {
        let short = Self.size(of: Self.short)
        let medium = Self.size(of: Self.medium)

        #expect(short.width > 0)
        #expect(short.width < medium.width)
    }

    @Test("a long line wraps rather than running off the screen")
    func longWrapsAtTheCap() {
        let medium = Self.size(of: Self.medium)
        let long = Self.size(of: Self.long)

        // Wrapped, so it is TALLER than the one-liner. Height is the honest test of
        // wrapping; the width bound is `bubblesStayOffTheCrane` below.
        #expect(long.height > medium.height)
        #expect(long.width > medium.width)
    }

    /// The bubble is drawn on a 1366-point-wide frame and has to leave room for the
    /// crane it is talking about — the cap plus the bubble's own furniture, and no more.
    @Test("no bubble outgrows its cap")
    func bubblesStayOffTheCrane() {
        let furniture = 2 * 30 + SpeechBubbleShape.bulge(forTailHeight: SpeechBubbleView.tailHeight)
        let widest = SpeechBubbleView.maximumTextWidth + furniture

        for text in [Self.short, Self.medium, Self.long] {
            #expect(Self.size(of: text).width <= widest + 1)
            #expect(Self.size(of: text).width <= 1366 / 2 + furniture)
        }
    }

    /// The tail hangs below the body and its horn reaches out past the leading edge, so
    /// the rendered bounds have to cover both — otherwise the tail is drawn outside the
    /// view and the first ancestor that clips takes its point off.
    @Test("the tail is inside the bubble's own bounds")
    func tailIsNotClipped() {
        let rendered = Self.size(of: Self.short)
        let bulge = SpeechBubbleShape.bulge(forTailHeight: SpeechBubbleView.tailHeight)

        #expect(rendered.height >= SpeechBubbleView.minimumHeight)
        #expect(rendered.width >= bulge)
    }
}
