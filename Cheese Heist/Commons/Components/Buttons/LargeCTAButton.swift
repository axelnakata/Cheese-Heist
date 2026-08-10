//
//  LargeCTAButton.swift
//  Cheese Heist
//
//  PRD §7.6 — Figma 639:65. 88.54 × 86.54, radius .pill, icon-only, SF Symbol at 36 pt.
//

import SwiftUI

struct LargeCTAButton: View {

    private enum Metric {
        static let width: CGFloat = 88.54
        static let height: CGFloat = 86.54
        static let symbolSize: CGFloat = 36
    }

    let icon: LargeCTAButtonIcon
    let action: () -> Void

    @Environment(\.layoutScale) private var scale
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Image(systemName: icon.systemName)
                .font(.system(size: Metric.symbolSize * scale, weight: .bold))
                .foregroundStyle(AppColor.textOnAccent)
                .frame(width: Metric.width * scale, height: Metric.height * scale)
        }
        .buttonStyle(AccentPillButtonStyle())
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
