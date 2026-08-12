//
//  DialogueTextWidth.swift
//  Cheese Heist
//
//  How wide the speech bubble's text wants to be. One number, measured.
//
//  ═══ WHY THIS IS NOT DONE WITH `.frame(maxWidth:)`. ═══
//
//  "Hug the text, but stop at a cap" has no honest spelling in SwiftUI's layout
//  vocabulary. `.frame(maxWidth:)` reports the width it was PROPOSED, so a bubble in a
//  full-width parent always came back full width — which is the bug this fixes.
//  `.fixedSize(horizontal: true)` on top of it does clamp the width, but it resolves the
//  HEIGHT from the unclamped single-line pass, so a long line silently became a
//  one-line bubble with the rest of the sentence cropped off. That failure is worse than
//  the one it replaces: the first is ugly, the second loses words.
//
//  So the width is measured directly and handed to `.frame(width:)`, which proposes and
//  reports the same number and has no ambiguity in it at all.
//
//  UNDER-MEASURING IS SAFE, OVER-MEASURING IS SAFE. Too narrow and the text takes an
//  extra line inside a bubble sized for it; too wide and the bubble carries a little
//  more air. Neither crops. That is what makes approximating the bold runs acceptable.
//

import SwiftUI
import UIKit

enum DialogueTextWidth {

    /// The natural single-line width of `text` in `style`, capped at `cap`.
    static func measure(_ text: AttributedString, style: TextStyle, cap: CGFloat) -> CGFloat {
        let font = AppFontResolver.uiFont(named: style.fontName, size: style.size)
        let plain = String(text.characters)

        let attributed = NSAttributedString(
            string: plain,
            attributes: [.font: font, .kern: style.tracking]
        )

        let unbounded = CGSize(width: .greatestFiniteMagnitude, height: font.lineHeight * 2)
        let natural = attributed.boundingRect(
            with: unbounded, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil
        ).width

        // Rounded up: `boundingRect` returns a fractional width and the renderer lays
        // out on whole points, so the last glyph of a just-fitting line would wrap.
        return min(natural.rounded(.up) + Self.boldAllowance, cap)
    }

    /// Bold runs measure wider than the regular face they are approximated with. One
    /// em of the dialogue size covers the two or three emphasised words a beat carries.
    private static let boldAllowance: CGFloat = 24
}
