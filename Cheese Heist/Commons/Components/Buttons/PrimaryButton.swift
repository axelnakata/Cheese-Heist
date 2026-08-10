//
//  PrimaryButton.swift
//  Cheese Heist
//
//  PRD §7.6 — Figma 639:64. 210 × 78.14, radius .pill, accent fill, white 1.27 stroke.
//

import SwiftUI

struct PrimaryButton: View {

    private enum Metric {
        static let width: CGFloat = 210
        static let height: CGFloat = 78.14
        static let horizontalPadding: CGFloat = 19.07
    }

    let title: String
    let action: () -> Void

    @Environment(\.layoutScale) private var scale
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Text(title)
                .appText(AppFont.title)
                .foregroundStyle(AppColor.textOnAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, Metric.horizontalPadding * scale)
                .frame(minWidth: Metric.width * scale, minHeight: Metric.height * scale)
        }
        .buttonStyle(AccentPillButtonStyle())
        .opacity(isEnabled ? 1 : 0.45)
    }
}

#Preview("On parchment") {
    VStack(spacing: AppSpacing.m) {
        PrimaryButton(title: "Play") {}
        PrimaryButton(title: "Continue") {}
        PrimaryButton(title: "Play") {}
            .disabled(true)
    }
    .previewBackdrop(.parchment)
}

#Preview("On camera feed") {
    PrimaryButton(title: "Start") {}
        .previewBackdrop(.cameraFeed)
}
