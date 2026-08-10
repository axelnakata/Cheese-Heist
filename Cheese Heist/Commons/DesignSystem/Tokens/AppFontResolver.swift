//
//  AppFontResolver.swift
//  Cheese Heist
//
//  Risk R-07 (PRD §13) — a missing or misnamed custom font falls back to San Francisco
//  silently, and the bug survives all the way to a classroom. This makes it loud.
//
//  The names in `AppFont.Family` are PostScript names, not filenames: Mickies ships as
//  `Mickies.otf` and registers as `MickiesRegular`.
//

import UIKit

enum AppFontResolver {

    /// Resolves a token's font, trapping in debug builds if it is not registered.
    ///
    /// Release builds fall back to the system font — a wrong typeface is bad, a crashed
    /// classroom is worse.
    static func uiFont(named name: String, size: CGFloat) -> UIFont {
        guard let font = UIFont(name: name, size: size) else {
            assertionFailure(
                """
                Font "\(name)" is not registered. Check that the file is in \
                Resources/Fonts, is a member of the app target, is listed in \
                Info.plist → UIAppFonts, and that this is its PostScript name.
                """
            )
            return .systemFont(ofSize: size)
        }
        return font
    }

    /// Verifies every token in `AppFont.allStyles` resolves. Call once at launch.
    ///
    /// Returns the names that failed, so a caller can surface them; empty means healthy.
    @discardableResult
    static func verifyRegisteredFonts() -> [String] {
        let missing = AppFont.allStyles
            .map(\.fontName)
            .filter { UIFont(name: $0, size: 12) == nil }

        assert(missing.isEmpty, "Unregistered fonts: \(missing.joined(separator: ", "))")
        return missing
    }
}
