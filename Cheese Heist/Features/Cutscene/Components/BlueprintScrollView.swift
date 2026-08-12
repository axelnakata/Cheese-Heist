//
//  BlueprintScrollView.swift
//  Cheese Heist
//
//  PRD-Cutscene §6.4 — the rolled blueprint with its radial glow effect behind it.
//  From `Docs/cutscene frames/cutscene 6.png`: the blueprint scroll sits at screen
//  centre with a radial light burst behind it.
//

import SwiftUI

struct BlueprintScrollView: View {

    @Environment(\.layoutScale) private var scale
    @State private var glowRotation: Angle = .zero

    private enum Metric {
        /// Both are the Figma frame sizes from `cutscene 6` (667:76): the glow is the
        /// 795 × 795 burst, the scroll a 481 × 481 box.
        ///
        /// Sized by WIDTH, because both assets are square canvases with the artwork
        /// occupying a band across the middle — the scroll's own pixels only span
        /// 295 × 179 of its 481 × 481. Framing to a height made it draw at about a third
        /// of its intended size.
        static let scrollWidth: CGFloat = 481
        static let glowWidth: CGFloat = 795
        static let glowOpacity: CGFloat = 0.9
        static let glowRevolution: Double = 20
    }

    var body: some View {
        ZStack {
            // Radial glow — slowly rotating.
            Image("blueprint_glow")
                .resizable()
                .scaledToFit()
                .frame(width: Metric.glowWidth * scale)
                .rotationEffect(glowRotation)
                .opacity(Metric.glowOpacity)
                .onAppear {
                    withAnimation(
                        .linear(duration: Metric.glowRevolution)
                        .repeatForever(autoreverses: false)
                    ) {
                        glowRotation = .degrees(360)
                    }
                }

            // The scroll on top. Its tilt is already baked into the artwork — the
            // source SVG rotates the image by −17.86° — so rotating again here left it
            // lying at twice the angle Figma draws it at.
            Image("blueprint_scroll")
                .resizable()
                .scaledToFit()
                .frame(width: Metric.scrollWidth * scale)
        }
    }
}

#Preview("On scrim") {
    ZStack {
        ScrimOverlay()
        BlueprintScrollView()
    }
    .previewBackdrop(.cameraFeed)
}
