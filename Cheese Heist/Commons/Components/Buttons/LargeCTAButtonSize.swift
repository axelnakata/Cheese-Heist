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

    /// Figma 857:230 / 857:232 (and the fail screens' 875:598 / 875:601) — the result
    /// frames' Retry and Next. Bigger than the standard button, but not by much: it was
    /// built at 155pt against a measured Figma circle of ~125–127pt, which read as
    /// oversized on the actual result screen.
    case celebration

    var width: CGFloat {
        switch self {
        case .standard: 88.54
        case .celebration: 126
        }
    }

    var height: CGFloat {
        switch self {
        case .standard: 86.54
        case .celebration: 126
        }
    }

    /// The SF Symbol's point size. Measured off Figma 857:230: a 126pt circle with 18pt
    /// padding on each side leaves a 90pt icon slot, and the design authors the glyph at
    /// 75pt inside it — a proportionally bigger glyph than the standard button's 0.41.
    var symbolSize: CGFloat {
        switch self {
        case .standard: 36
        case .celebration: 75
        }
    }

    /// ═══ NOT `AppRadius.pill`. ═══
    ///
    /// That token is 63.57 — chosen to exceed half of the 78.14pt button height so the
    /// standard controls clamp to a capsule. At 126pt it no longer clearly exceeds half
    /// (63), so a fixed token would drift between circle and squircle as the button's own
    /// size changes. Half the longest side is a capsule at every size: it clamps to 43.27
    /// on the standard button, which is exactly what the token was already producing
    /// there, and to a true circle on the square one.
    var cornerRadius: CGFloat { max(width, height) / 2 }
}
