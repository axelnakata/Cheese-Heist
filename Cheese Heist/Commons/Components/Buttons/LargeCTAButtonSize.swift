//
//  LargeCTAButtonSize.swift
//  Cheese Heist
//
//  How big the icon-only CTA is drawn. A second Figma frame, not a free parameter — the
//  same button appears at two deliberate sizes and a call site may pick between them but
//  may not invent a third.
//
//  A sibling of `LargeCTAButtonIcon` rather than a nested type, for the same reason: one
//  type per file (§8.4), and a call site reads `size: .celebration`.
//

import CoreGraphics

enum LargeCTAButtonSize {

    /// PRD §7.6, Figma 639:65. Blueprint navigation and every in-flow control.
    case standard

    /// Figma 800:197 — the success frame's Retry and Next. Nearly twice the standard
    /// button: it is the only thing on screen a child is meant to hit, from arm's length,
    /// while holding an iPad in both hands.
    case celebration

    var width: CGFloat {
        switch self {
        case .standard: 88.54
        case .celebration: 155
        }
    }

    var height: CGFloat {
        switch self {
        case .standard: 86.54
        case .celebration: 155
        }
    }

    /// The SF Symbol's point size. The celebration button carries a proportionally
    /// larger glyph than the standard one — 0.46 of the button against 0.41 — which is
    /// what the success frame draws.
    var symbolSize: CGFloat {
        switch self {
        case .standard: 36
        case .celebration: 72
        }
    }

    /// ═══ NOT `AppRadius.pill`. ═══
    ///
    /// That token is 63.57 — chosen to exceed half of the 78.14pt button height so the
    /// standard controls clamp to a capsule. At 155pt it stops exceeding half, and the
    /// success frame's circles came out as squircles. Half the longest side is a capsule
    /// at every size: it clamps to 43.27 on the standard button, which is exactly what
    /// the token was already producing there, and to a true circle on the square one.
    var cornerRadius: CGFloat { max(width, height) / 2 }
}
