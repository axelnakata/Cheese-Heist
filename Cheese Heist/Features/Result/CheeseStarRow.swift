//
//  CheeseStarRow.swift
//  Cheese Heist
//
//  PRD-Level1 §3 Phase 12: three cheese stars on the success screen.
//
//  THE NAME IS THE ASSET CATALOGUE'S, NOT THE FIGMA EXPORT'S. This asked for
//  `cheese-star` while the imageset is `cheese_star`, and `Image(_:)` has no failure
//  path — a name that does not resolve draws nothing at all and logs once. So the
//  success screen lost its stars silently. `BundledAssetTests` now loads this name out
//  of the real bundle, which is the only way a typo in a string literal gets caught.
//
//  ═══ THREE OF ONE SIZE, AND THAT SIZE IS 144pt. ═══
//
//  These were 60 / 80 / 60, which is neither the frame's sizes nor its shape — the
//  middle one is not bigger, and none of them is that small. At 60pt over a live camera
//  feed they read as emoji dropped on the picture rather than as the reward for
//  finishing the level.
//

//import SwiftUI
//
//struct CheeseStarRow: View {
//
//    /// The imageset in `Assets.xcassets`. Published so a test can assert it loads.
//    static let assetName = "cheese_star"
//
//    @Environment(\.layoutScale) private var scale
//
//    @State private var showStars = [false, false, false]
//
//    /// Figma 800:197, at the 1366 × 1024 design scale.
//    private enum Metric {
//        /// How wide the drawn wedge reads, and how much air sits between two of them.
//        static let wedgeWidth: CGFloat = 144
//        static let wedgeGap: CGFloat = 39
//
//        /// `cheese_star` is a square canvas with transparent margins — the wedge itself
//        /// is 52.9% of its width and 46.8% of its height. The image frame therefore has
//        /// to be that much larger than the wedge, and the row's spacing that much
//        /// smaller, or the wedges come out too small AND too far apart. Measured off the
//        /// asset, not guessed.
//        static let artFillWidth: CGFloat = 0.529
//        static let artFillHeight: CGFloat = 0.468
//    }
//
//    /// The square frame that renders a `wedgeWidth`-wide wedge.
//    private var frameSide: CGFloat { Metric.wedgeWidth / Metric.artFillWidth }
//
//    /// Negative, and deliberately so: the frames overlap by exactly the transparent
//    /// margin they carry, which leaves `wedgeGap` between the wedges themselves.
//    private var spacing: CGFloat { Metric.wedgeGap - (frameSide - Metric.wedgeWidth) }
//
//    /// ═══ THE ROW MEASURES AS ITS WEDGES, NOT AS ITS CANVAS. ═══
//    ///
//    /// Also negative. Those transparent margins are 72pt of nothing at the top and
//    /// bottom of a 272pt frame, and a caller stacking this between a subtitle and a
//    /// mouse has no way to know that — it reads the row as 272 tall and spaces
//    /// accordingly, which is 145pt of invisible padding it never asked for and cannot
//    /// see. Collapsing it here means `SuccessOverlay`'s gaps are the gaps in the frame.
//    private var marginCollapse: CGFloat { -(frameSide - frameSide * Metric.artFillHeight) / 2 }
//
//    var body: some View {
//        HStack(spacing: spacing * scale) {
//            ForEach(0..<3, id: \.self) { index in
//                Image(Self.assetName)
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: frameSide * scale, height: frameSide * scale)
//                    .scaleEffect(showStars[index] ? 1.0 : 0.0)
//                    .opacity(showStars[index] ? 1.0 : 0.0)
//                    .animation(
//                        .spring(response: 0.5, dampingFraction: 0.6)
//                        .delay(Double(index) * 0.2),
//                        value: showStars[index]
//                    )
//            }
//        }
//        .padding(.vertical, marginCollapse * scale)
//        .onAppear { animateStars() }
//    }
//
//    private func animateStars() {
//        for starIndex in 0..<3 {
//            DispatchQueue.main.asyncAfter(deadline: .now() + Double(starIndex) * 0.2) {
//                showStars[starIndex] = true
//            }
//        }
//    }
//}
//
//#Preview {
//    CheeseStarRow()
//        .previewBackdrop(.cameraFeed)
//}

import SwiftUI

struct CheeseStarRow: View {

    /// Jumlah bintang yang didapat (misal: 0, 1, 2, atau 3)
    let earnedStars: Int

    static let assetName = "cheese_star"

    @Environment(\.layoutScale) private var scale
    @State private var showStars = [false, false, false]

    private enum Metric {
        static let wedgeWidth: CGFloat = 144
        static let wedgeGap: CGFloat = 39
        static let artFillWidth: CGFloat = 0.529
        static let artFillHeight: CGFloat = 0.468
    }

    private var frameSide: CGFloat { Metric.wedgeWidth / Metric.artFillWidth }
    private var spacing: CGFloat { Metric.wedgeGap - (frameSide - Metric.wedgeWidth) }
    private var marginCollapse: CGFloat { -(frameSide - frameSide * Metric.artFillHeight) / 2 }

    var body: some View {
        HStack(spacing: spacing * scale) {
            ForEach(0..<3, id: \.self) { index in
                Image(Self.assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: frameSide * scale, height: frameSide * scale)
                    .scaleEffect(showStars[index] ? 1.0 : 0.0)
                    .opacity(showStars[index] ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.6),
                        value: showStars[index]
                    )
            }
        }
        .padding(.vertical, marginCollapse * scale)
        .task {
            // Menggunakan .task agar animasi & audio berjalan sinkron saat View muncul
            await animateAndPlayStars()
        }
    }

    private func animateAndPlayStars() async {
        let starTracks: [AudioTrack] = [.star1, .star2, .star3]
        
        // Loop sebanyak bintang yang didapatkan pemain
        for i in 0..<min(earnedStars, 3) {
            // 1. Tampilkan animasi bintang di UI
            withAnimation {
                showStars[i] = true
            }
            
            // 2. Putar SFX Bintang yang sesuai dan tunggu hingga selesai sebelum lanjut
            await AudioManager.shared.playSFXAndWait(track: starTracks[i])
        }
    }
}

#Preview {
    CheeseStarRow(earnedStars: 3)
        .previewBackdrop(.cameraFeed)
}
