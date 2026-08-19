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


import SwiftUI

struct CheeseStarRow: View {

    /// Jumlah bintang yang didapat (misal: 0, 1, 2, atau 3)
    var earnedStars: Int = 3

    static let assetName = "cheese_star"

    /// How many cheese are "earned" (solid). Stars beyond this count render as outlines.
    /// Defaults to 3 for backward compatibility with Level 1.
    var starCount: Int {
        get { earnedStars }
        set { earnedStars = newValue }
    }

    init(earnedStars: Int = 3) {
        self.earnedStars = earnedStars
    }

    init(starCount: Int) {
        self.earnedStars = starCount
    }

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
                Image(index < starCount ? Self.assetName : "cheese_empty")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: frameSide * scale, height: frameSide * scale)
                    .opacity(showStars[index] ? 1.0 : 0.0)
                    .scaleEffect(showStars[index] ? 1.0 : 0.0)
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

        // Loop 3 kali untuk memunculkan 3 keju (baik keju utuh maupun keju kosong) satu per satu dengan irama yang pas
        for starIndex in 0..<3 {
            // Jika keju didapatkan, putar audio bintang secara instan (non-blocking)
            if starIndex < min(earnedStars, 3) {
                AudioManager.shared.playSFX(starTracks[starIndex])
            }

            // Tampilkan animasi pop keju (baik keju utuh maupun kosong)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showStars[starIndex] = true
            }

            // Interval 350ms antarkeju agar suara setiap bintang terdengar terpisah dan jelas satu per satu
            try? await Task.sleep(nanoseconds: 350_000_000)
        }
    }
}

#Preview {
    CheeseStarRow(earnedStars: 2)
        .previewBackdrop(.cameraFeed)
}
