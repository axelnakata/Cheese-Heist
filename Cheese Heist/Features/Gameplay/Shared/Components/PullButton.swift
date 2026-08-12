// PullButton.swift — Cheese Heist
// PRD-Level1 D-2: PULL button commits roles and switches to joystick.

import SwiftUI

struct PullButton: View {

    let action: () -> Void

    @Environment(\.layoutScale) private var scale

    var body: some View {
        Button(action: action) {
            Text("PULL")
                .appText(AppFont.body)
                .foregroundStyle(AppColor.textOnAccent)
                .padding(.horizontal, AppSpacing.l * scale)
                .padding(.vertical, AppSpacing.m * scale)
                .background(
                    Capsule()
                        .fill(AppColor.accent)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(AppColor.accentStroke, lineWidth: AppStroke.button * scale)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PullButton(action: {})
        .previewBackdrop(.cameraFeed)
}
