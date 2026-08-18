//
//  LargeCTAButton.swift
//  Cheese Heist
//
//  PRD §7.6 — Figma 639:65. 88.54 × 86.54, radius .pill, icon-only, SF Symbol at 36 pt.
//  The success frame draws the same button at `.celebration` — see `LargeCTAButtonSize`.
//

import SwiftUI

struct LargeCTAButton: View {

    let icon: LargeCTAButtonIcon
    var size: LargeCTAButtonSize = .standard
    var tint: LargeCTAButtonTint = .primary
    let action: () -> Void

    @Environment(\.layoutScale) private var scale
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Image(systemName: icon.systemName)
                .font(.system(size: size.symbolSize(for: icon) * scale, weight: .bold))
                .foregroundStyle(AppColor.textOnAccent)
                .frame(width: size.width * scale, height: size.height * scale)
        }
        .buttonStyle(AccentPillButtonStyle(
            cornerRadius: size.cornerRadius,
            fillColor: tint.fillColor,
            pressedFillColor: tint.pressedFillColor
        ))
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel(icon.accessibilityLabel)
    }
}

#Preview("All variants — parchment") {
    HStack(spacing: AppSpacing.m) {
        ForEach(LargeCTAButtonIcon.allCases, id: \.self) { icon in
            LargeCTAButton(icon: icon) {}
        }
    }
    .previewBackdrop(.parchment)
}

#Preview("All variants — camera feed") {
    HStack(spacing: AppSpacing.m) {
        ForEach(LargeCTAButtonIcon.allCases, id: \.self) { icon in
            LargeCTAButton(icon: icon) {}
        }
    }
    .previewBackdrop(.cameraFeed)
}

#Preview("Celebration size — camera feed") {
    HStack(spacing: AppSpacing.m) {
        LargeCTAButton(icon: .retry, size: .celebration) {}
        LargeCTAButton(icon: .next, size: .standard) {}
        LargeCTAButton(icon: .next, size: .celebration) {}
    }
    .previewBackdrop(.cameraFeed)
}
