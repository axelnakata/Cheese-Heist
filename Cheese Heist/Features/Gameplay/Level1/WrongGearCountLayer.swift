//
//  WrongGearCountLayer.swift
//  Cheese Heist
//
//  Setup-only fallback screen shown when the child builds with fewer or more than 2 gears.
//  Dismissed via "I fixed it!" button.
//

import SwiftUI

struct WrongGearCountLayer: View {

    let issue: GearCountIssue
    let onFixed: () -> Void

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let titleGap: CGFloat = 28
        static let buttonGap: CGFloat = 36
        static let sideMargin: CGFloat = 60
    }

    var body: some View {
        ZStack {
            ScrimOverlay()

            VStack(spacing: Metric.titleGap * scale) {
                Text(Level1Script.wrongGearCountTitle)
                    .appText(AppFont.largeTitle)
                    .foregroundStyle(AppColor.textOnCamera)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                WrongGearCountIllustration()

                PrimaryButton(title: Level1Script.wrongGearCountButton, action: onFixed)
                    .padding(.top, Metric.buttonGap * scale)
            }
            .padding(.horizontal, Metric.sideMargin * scale)
        }
        .ignoresSafeArea()
    }
}

#Preview("On camera feed") {
    WrongGearCountLayer(issue: .tooFew, onFixed: {})
        .previewBackdrop(.cameraFeed)
}

#Preview("On parchment") {
    WrongGearCountLayer(issue: .tooMany(3), onFixed: {})
        .previewBackdrop(.parchment)
}
