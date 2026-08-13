//
//  AppFont.swift
//  Cheese Heist
//
//  PRD §7.3 — the five type tokens. Sizes are declared at the 1366 pt design scale and
//  are multiplied once, by `View.appText(_:)`.
//

import CoreGraphics

enum AppFont {

    /// PostScript names — these are what `UIFont(name:)` resolves, and they are *not*
    /// always the filename. Mickies ships as `Mickies.otf` but registers as
    /// `MickiesRegular`, with no hyphen. Verified against the font's `name` table;
    /// getting this wrong is risk R-07 (silent fallback to San Francisco).
    private enum Family {
        static let display = "MickiesRegular"
        static let regular = "Nunito-Regular"
        static let bold = "Nunito-Bold"
        static let extraBold = "Nunito-ExtraBold"
    }

    private static let standardTracking: CGFloat = 0.828

    /// Mickies Regular 64. Splash wordmark, "CHEESE SECURED!".
    static let largeTitle = TextStyle(
        fontName: Family.display, size: 64, lineHeight: 60, tracking: standardTracking
    )

    /// Nunito ExtraBold 36. Primary button labels, instruction chips, HUD headers.
    static let title = TextStyle(
        fontName: Family.extraBold, size: 36, lineHeight: 40, tracking: standardTracking
    )

    /// Nunito Bold 22. Section headers, "Great job!".
    static let subtitle = TextStyle(
        fontName: Family.bold, size: 22, lineHeight: 26, tracking: standardTracking
    )

    /// Nunito Regular 22. Body copy, blueprint instructions, tap hints.
    static let body = TextStyle(
        fontName: Family.regular, size: 22, lineHeight: 26, tracking: standardTracking
    )

    /// Nunito Regular 24. Speech bubbles only — promoted to its own token per OQ-2
    /// rather than absorbing a second 22/24 pt near-duplicate.
    static let dialogue = TextStyle(
        fontName: Family.regular, size: 24, lineHeight: 26, tracking: standardTracking
    )

    /// Nunito Bold 14. Small labels under icons (gear attribute bars).
    static let caption = TextStyle(
        fontName: Family.bold, size: 14, lineHeight: 18, tracking: standardTracking
    )

    /// Every token, for the font-registration check and design-system previews.
    static let allStyles: [TextStyle] = [largeTitle, title, subtitle, body, dialogue, caption]
}
