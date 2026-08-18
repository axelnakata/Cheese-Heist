//
//  LargeCTAButtonTint.swift
//  Cheese Heist
//
//  Which fill the icon-only CTA is drawn with. The result screen's Retry/Home use the
//  secondary blue so they don't compete with the primary yellow Next — a sibling of
//  `LargeCTAButtonIcon`/`LargeCTAButtonSize` for the same reason: a call site picks
//  between two named options, it does not invent a `Color`.
//

import SwiftUI

enum LargeCTAButtonTint {
    case primary
    case secondary
    case secondaryYellow
    case mainBlue

    var fillColor: Color {
        switch self {
        case .primary: AppColor.accent
        case .secondary: AppColor.accentSecondary
        case .secondaryYellow: AppColor.accentSecondaryYellow
        case .mainBlue: AppColor.accentMainBlue
        }
    }

    var pressedFillColor: Color {
        switch self {
        case .primary: AppColor.accentPressed
        case .secondary: AppColor.accentSecondaryPressed
        case .secondaryYellow: AppColor.accentSecondaryYellowPressed
        case .mainBlue: AppColor.accentMainBluePressed
        }
    }
}
