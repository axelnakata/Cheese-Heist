//
//  RecommendedPositionStrip.swift
//  Cheese Heist
//
//  The "Recommended Position" strip at the top of the scanning phase — three postures of
//  iPad over table, two ticked and one crossed.
//
//  ═══ SIZED BY WIDTH, FROM THE FIGMA FRAME. ═══
//
//  615 × 215 in the 1366 × 1024 design frame, so the width is what is pinned and the
//  height follows. The first version framed it to a 140 pt HEIGHT against an asset that
//  had been exported onto a square canvas with an opaque white backdrop, so the strip
//  drew at roughly a quarter of its intended size inside a white box floating over the
//  camera feed. The asset is now a transparent 3x render of `positionGuideline.svg` at
//  the real aspect, which is why `scaledToFit` can be trusted here.
//

import SwiftUI

struct RecommendedPositionStrip: View {

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        /// Both measured off the exported frames rather than eyeballed: in
        /// `cutscene guidelines - Fall Back.png` the navy strip spans x 376…987 and
        /// y 54…264 of the 1366 × 1024 design frame.
        static let width: CGFloat = 615
        static let topPadding: CGFloat = 54
    }

    var body: some View {
        VStack {
            Image("position_guideline")
                .resizable()
                .scaledToFit()
                .frame(width: Metric.width * scale)
                .padding(.top, Metric.topPadding * scale)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
}

#Preview("Camera feed") {
    RecommendedPositionStrip()
        .previewBackdrop(.cameraFeed)
}

#Preview("Parchment") {
    RecommendedPositionStrip()
        .previewBackdrop(.parchment)
}
