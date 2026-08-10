//
//  SuccessOverlay.swift
//  Cheese Heist
//
//  Phase 13: "CHEESE SECURED!", three cheese stars, the mouse holding its prize, and
//  the two actions.
//
//  AN OVERLAY, NOT A ROUTE. The AR scene stays live and frozen behind the scrim — the
//  crane the child built is still standing there, which is the reward. Routing to a
//  success screen would tear the ARView down and replace it with a picture of nothing.
//

import SwiftUI

struct SuccessOverlay: View {

    /// Copy is passed in, not read from a level's script — every level ends here and
    /// only the words differ.
    let title: String
    let subtitle: String
    let onRetry: () -> Void
    let onNext: () -> Void

    @Environment(\.layoutScale) private var scale
    @State private var hasEntered = false

    private enum Metric {
        static let mouseHeight: CGFloat = 445
        static let inset: CGFloat = 64
    }

    var body: some View {
        ZStack {
            ScrimOverlay()

            VStack(spacing: AppSpacing.m * scale) {
                Text(title)
                    .appText(AppFont.largeTitle)
                    .foregroundStyle(AppColor.textOnCamera)

                Text(subtitle)
                    .appText(AppFont.title)
                    .foregroundStyle(AppColor.accent)

                CheeseStarRow()

                Image(MouseSprite.happy.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: Metric.mouseHeight * scale)
            }
            .padding(.top, AppSpacing.xl * scale)

            SuccessActionsRow(onRetry: onRetry, onNext: onNext)
                .padding(Metric.inset * scale)
        }
        .opacity(hasEntered ? 1 : 0)
        .scaleEffect(hasEntered ? 1 : 0.92)
        .onAppear {
            withAnimation(.easeOut(duration: AppDuration.celebrationEntry)) {
                hasEntered = true
            }
        }
    }
}

#Preview {
    SuccessOverlay(
        title: "CHEESE SECURED!",
        subtitle: "Great job!",
        onRetry: {},
        onNext: {}
    )
        .previewBackdrop(.cameraFeed)
}
