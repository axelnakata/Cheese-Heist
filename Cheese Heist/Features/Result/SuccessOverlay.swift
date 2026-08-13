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
//  ═══ THE CONTENT HANGS FROM THE TOP; THE ACTIONS SIT ON THE FLOOR. ═══
//
//  Both were centred, and centring is why the screen came out wrong in three ways at
//  once: the title floated into the middle, a 445pt mouse — a third taller than the
//  frame's 331 — pushed everything else off its marks, and the two buttons ended up
//  level with the mouse's ears instead of in the bottom corners. The stack below is
//  pinned to the top with the frame's own gaps between its rows, so each element lands
//  where 800:197 puts it whatever the ones above it measure.
//

//import SwiftUI
//
//struct SuccessOverlay: View {
//
//    /// Copy is passed in, not read from a level's script — every level ends here and
//    /// only the words differ.
//    let title: String
//    let subtitle: String
//    let onRetry: () -> Void
//    let onNext: () -> Void
//
//    @Environment(\.layoutScale) private var scale
//    @State private var hasEntered = false
//
//    /// Figma 800:197, at the 1366 × 1024 design scale.
//    private enum Metric {
//        static let titleTop: CGFloat = 111
//        static let subtitleGap: CGFloat = 0
//        static let starsGap: CGFloat = 63
//        static let mouseGap: CGFloat = 100
//
//        /// `mice_happy` — the pose that is holding the cheese. 331pt is the frame's,
//        /// measured off the export; the mouse was previously drawn at 445.
//        static let mouseHeight: CGFloat = 331
//    }
//
//    var body: some View {
//        ZStack {
//            ScrimOverlay()
//            celebration
//            SuccessActionsRow(onRetry: onRetry, onNext: onNext)
//        }
//        .opacity(hasEntered ? 1 : 0)
//        .scaleEffect(hasEntered ? 1 : 0.92)
//        .onAppear {
//            withAnimation(.easeOut(duration: AppDuration.celebrationEntry)) {
//                hasEntered = true
//            }
//        }
//    }
//
//    private var celebration: some View {
//        VStack(spacing: 0) {
//            Text(title)
//                .appText(AppFont.largeTitle)
//                .foregroundStyle(AppColor.textOnCamera)
//
//            Spacer().frame(height: Metric.subtitleGap * scale)
//
//            Text(subtitle)
//                .appText(AppFont.title)
//                .foregroundStyle(AppColor.accent)
//
//            Spacer().frame(height: Metric.starsGap * scale)
//
//            CheeseStarRow()
//
//            Spacer().frame(height: Metric.mouseGap * scale)
//
//            Image(MouseSprite.happy.assetName)
//                .resizable()
//                .scaledToFit()
//                .frame(height: Metric.mouseHeight * scale)
//
//            Spacer(minLength: 0)
//        }
//        .padding(.top, Metric.titleTop * scale)
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
//    }
//}
//
//#Preview {
//    SuccessOverlay(
//        title: "CHEESE SECURED!",
//        subtitle: "Great job!",
//        onRetry: {},
//        onNext: {}
//    )
//        .previewBackdrop(.cameraFeed)
//}

import SwiftUI

struct SuccessOverlay: View {

    let title: String
    let subtitle: String
    /// Jumlah bintang yang diraih oleh pemain (0 - 3)
    let earnedStars: Int
    let onRetry: () -> Void
    let onNext: () -> Void

    @Environment(\.layoutScale) private var scale
    @State private var hasEntered = false
    @State private var canStartStarAnimation = false

    private enum Metric {
        static let titleTop: CGFloat = 111
        static let subtitleGap: CGFloat = 0
        static let starsGap: CGFloat = 63
        static let mouseGap: CGFloat = 100
        static let mouseHeight: CGFloat = 331
    }

    var body: some View {
        ZStack {
            ScrimOverlay()
            celebration
            SuccessActionsRow(onRetry: onRetry, onNext: onNext)
        }
        .opacity(hasEntered ? 1 : 0)
        .scaleEffect(hasEntered ? 1 : 0.92)
        .task {
            // 1. Jalankan animasi masuk overlay
            withAnimation(.easeOut(duration: AppDuration.celebrationEntry)) {
                hasEntered = true
            }
            
            // 2. Putar audio Success/Fail terlebih dahulu
            let statusTrack: AudioTrack = earnedStars > 0 ? .success : .fail
            await AudioManager.shared.playSFXAndWait(track: statusTrack)
            
            // 3. Setelah audio Success/Fail selesai, izinkan animasi Bintang dimulai
            canStartStarAnimation = true
        }
    }

    private var celebration: some View {
        VStack(spacing: 0) {
            Text(title)
                .appText(AppFont.largeTitle)
                .foregroundStyle(AppColor.textOnCamera)

            Spacer().frame(height: Metric.subtitleGap * scale)

            Text(subtitle)
                .appText(AppFont.title)
                .foregroundStyle(AppColor.accent)

            Spacer().frame(height: Metric.starsGap * scale)

            // Bintang hanya akan dirender dan memutar suaranya jika audio Success sudah selesai
            if canStartStarAnimation {
                CheeseStarRow(earnedStars: earnedStars)
            } else {
                // Placeholder kasat mata untuk menjaga layout/spacing SwiftUI tetap konsisten
                CheeseStarRow(earnedStars: 0)
                    .hidden()
            }

            Spacer().frame(height: Metric.mouseGap * scale)

            Image(MouseSprite.happy.assetName)
                .resizable()
                .scaledToFit()
                .frame(height: Metric.mouseHeight * scale)

            Spacer(minLength: 0)
        }
        .padding(.top, Metric.titleTop * scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    SuccessOverlay(
        title: "CHEESE SECURED!",
        subtitle: "Great job!",
        earnedStars: 3,
        onRetry: {},
        onNext: {}
    )
    .previewBackdrop(.cameraFeed)
}
