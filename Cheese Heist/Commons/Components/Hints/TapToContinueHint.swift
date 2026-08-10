//
//  TapToContinueHint.swift
//  Cheese Heist
//
//  PRD §7.6 — Figma 539:88 / 436:175. .body in textOnCamera, 1 s pulse loop.
//

import SwiftUI

struct TapToContinueHint: View {

    var title: String = "Tap to continue"

    var body: some View {
        Text(title)
            .appText(AppFont.body)
            .foregroundStyle(AppColor.textOnCamera)
            .pulsing(period: 1)
            .accessibilityLabel(title)
    }
}

#Preview("On camera feed") {
    VStack(spacing: AppSpacing.l) {
        TapToContinueHint()
        TapToContinueHint(title: "Tap to play")
    }
    .previewBackdrop(.cameraFeed)
}

#Preview("On parchment") {
    TapToContinueHint()
        .previewBackdrop(.parchment)
}
