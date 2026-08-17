//
//  RecommendedPositionStrip.swift
//  Cheese Heist
//
//  The "Recommended Position" strip at the top of the scanning phase — three postures of
//  iPad over table, two ticked and one crossed.
//
//  ═══ THE LABEL IS NATIVE TEXT, NOT PART OF THE RASTER. ═══
//
//  `position_guideline.png` used to bake the "Recommended Position" pill into the same
//  image as the illustration box, drawn as a tab plugging into the box's top edge with no
//  gap between them — a deliberate Figma treatment, but on device it read as two pills
//  badly overlapping rather than a label attached to a card. The source composite has no
//  clean seam to crop at either: the box's own top border is only fully drawn outside the
//  pill's footprint, so any crop line either leaves a stray shadow nub under the label or
//  clips the box's rounded corners. Splitting the label out as real text sidesteps both —
//  it gets its own `Capsule`, in the same navy-chip styling `InstructionChip` already uses
//  a beat later on this same screen, with a real `AppSpacing` gap above the box instead of
//  a baked-in seam. The asset now starts below where the pill used to sit, and is clipped
//  to a rounded rect in code so its own top edge (never fully drawn in the source, since
//  the pill covered most of it) is always clean regardless of what the crop line caught.
//

import SwiftUI

struct RecommendedPositionStrip: View {

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        /// Box width, read off the Figma frame — unchanged by the label split.
        static let width: CGFloat = 615
        static let topPadding: CGFloat = 54
        static let boxCornerRadius: CGFloat = AppRadius.chip
        static let pillHorizontalPadding: CGFloat = 28
        static let pillVerticalPadding: CGFloat = 14
    }

    var body: some View {
        VStack {
            VStack(spacing: AppSpacing.xs * scale) {
                pill
                Image("position_guideline")
                    .resizable()
                    .scaledToFit()
                    .clipShape(
                        RoundedRectangle(cornerRadius: Metric.boxCornerRadius * scale, style: .continuous)
                    )
            }
            .frame(width: Metric.width * scale)
            .padding(.top, Metric.topPadding * scale)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    private var pill: some View {
        Text(CutsceneScript.recommendedPositionTitle)
            .appText(AppFont.title)
            .foregroundStyle(AppColor.textOnCamera)
            .padding(.horizontal, Metric.pillHorizontalPadding * scale)
            .padding(.vertical, Metric.pillVerticalPadding * scale)
            .background(Capsule().fill(AppGradient.navyChip))
            .overlay(Capsule().strokeBorder(AppColor.strokeChip, lineWidth: AppStroke.chip * scale))
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
