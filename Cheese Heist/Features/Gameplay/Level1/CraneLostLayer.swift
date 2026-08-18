//
//  CraneLostLayer.swift
//  Cheese Heist
//
//  Mid-game overlay shown automatically when tracking is lost (the crane leaves camera view).
//  Disappears the instant the crane is detected back in frame.
//

import SwiftUI

struct CraneLostLayer: View {

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let mouseHeight: CGFloat = 340
        static let bottomPadding: CGFloat = 30
        static let leadingPadding: CGFloat = 40
        static let mouseBubbleSpacing: CGFloat = -24
        static let bubbleOffsetY: CGFloat = -110
    }

    var body: some View {
        ZStack {
            ScrimOverlay()

            CraneAlignmentIllustration()

            VStack {
                Spacer()
                HStack(alignment: .bottom, spacing: Metric.mouseBubbleSpacing * scale) {
                    mouseImage

                    SpeechBubbleView(
                        text: AttributedString(Level1Script.craneLostSpeech),
                        isRevealComplete: .constant(true)
                    )
                    .offset(y: Metric.bubbleOffsetY * scale)

                    Spacer()
                }
                .padding(.leading, Metric.leadingPadding * scale)
                .padding(.bottom, Metric.bottomPadding * scale)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var mouseImage: some View {
        if UIImage(named: "mouse_panic1") != nil {
            Image("mouse_panic1")
                .resizable()
                .scaledToFit()
                .frame(height: Metric.mouseHeight * scale)
                .zIndex(1)
        } else if UIImage(named: "Mouse_panic1") != nil {
            Image("Mouse_panic1")
                .resizable()
                .scaledToFit()
                .frame(height: Metric.mouseHeight * scale)
                .zIndex(1)
        } else {
            Image("Mouse_searching")
                .resizable()
                .scaledToFit()
                .frame(height: Metric.mouseHeight * scale)
                .zIndex(1)
        }
    }
}

#Preview("On camera feed") {
    CraneLostLayer()
        .previewBackdrop(.cameraFeed)
}

#Preview("On parchment") {
    CraneLostLayer()
        .previewBackdrop(.parchment)
}
