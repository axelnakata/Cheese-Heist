//
//  View+TextStyle.swift
//  Cheese Heist
//
//  PRD §7.3 — the only place line-height maths exists.
//

import SwiftUI

private struct AppTextModifier: ViewModifier {

    let style: TextStyle

    @Environment(\.layoutScale) private var scale

    func body(content: Content) -> some View {
        let size = style.size * scale
        let uiFont = AppFontResolver.uiFont(named: style.fontName, size: size)

        // SwiftUI's `lineSpacing` is additive and cannot be negative. `largeTitle` asks
        // for 60 pt leading on a 64 pt font, so the delta clamps to 0 and the token
        // accepts default leading — indistinguishable on the 1–2 line strings it is used
        // on. Do not reach for AttributedString to force it (PRD §7.3).
        let extraLeading = max(0, style.lineHeight * scale - uiFont.lineHeight)

        return content
            // `fixedSize:` rather than `size:` — LayoutScale already does the scaling, and
            // letting Dynamic Type scale on top of it would break the 1366 pt design grid.
            .font(.custom(style.fontName, fixedSize: size))
            .tracking(style.tracking * scale)
            .lineSpacing(extraLeading)
            .padding(.vertical, extraLeading / 2)
    }
}

extension View {

    /// Applies a design-system type token: family, scaled size, tracking and leading.
    func appText(_ style: TextStyle) -> some View {
        modifier(AppTextModifier(style: style))
    }
}
