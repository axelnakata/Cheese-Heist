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
        static let mouseHeight: CGFloat = 150
        static let topPadding: CGFloat = 36
        static let boxCornerRadius: CGFloat = 18
        static let boxPaddingHorizontal: CGFloat = 28
        static let boxPaddingVertical: CGFloat = 18
        static let boxMaxWidth: CGFloat = 780
        static let strokeWidth: CGFloat = 2
    }

    var body: some View {
        ZStack {
            ScrimOverlay()

            CraneAlignmentIllustration()

            VStack {
                topInstructionBanner
                    .padding(.top, Metric.topPadding * scale)
                Spacer()
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Instruction Banner (Dialog Box + Mouse Searching Direct)
    private var topInstructionBanner: some View {
        ZStack(alignment: .bottomTrailing) {
            Text(Level1Script.craneLostSpeech)
                .appText(AppFont.title)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: Metric.boxMaxWidth * scale)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Metric.boxPaddingHorizontal * scale)
                .padding(.vertical, Metric.boxPaddingVertical * scale)
                .background(
                    RoundedRectangle(cornerRadius: Metric.boxCornerRadius * scale, style: .continuous)
                        .fill(AppGradient.navyChip.opacity(0.85))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Metric.boxCornerRadius * scale, style: .continuous)
                        .stroke(Color.white, lineWidth: Metric.strokeWidth * scale)
                )
                .shadow(color: .black.opacity(0.25), radius: 8 * scale, x: 0, y: 4 * scale)
                .padding(.trailing, (Metric.mouseHeight * 0.35) * scale)

            Image("Mouse_searching")
                .resizable()
                .scaledToFit()
                .frame(height: Metric.mouseHeight * scale)
                .offset(x: (Metric.mouseHeight * 0.25) * scale, y: (Metric.mouseHeight * 0.2) * scale)
                .zIndex(1)
        }
        .fixedSize(horizontal: true, vertical: true)
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
