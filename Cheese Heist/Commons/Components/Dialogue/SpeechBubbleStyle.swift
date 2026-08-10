// SpeechBubbleStyle.swift — Cheese Heist
// PRD §7.6 — bubble fill variants.

import SwiftUI

enum SpeechBubbleStyle {
    /// Default: cheese-yellow fill, dark text.
    case accent
    /// Parchment fill, dark text — Level 1 dialogue.
    case parchment

    var fillColor: Color {
        switch self {
        case .accent:    return AppColor.accent
        case .parchment: return AppColor.surfaceBackground
        }
    }

    var textColor: Color {
        switch self {
        case .accent:    return AppColor.textPrimary
        case .parchment: return AppColor.textPrimary
        }
    }
}
