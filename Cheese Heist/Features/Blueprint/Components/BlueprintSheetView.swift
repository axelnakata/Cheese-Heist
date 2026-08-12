//
//  BlueprintSheetView.swift
//  Cheese Heist
//
//  PRD §11.4 — the navy blueprint sheet: `blueprint_bg` is the pre-rendered scroll +
//  grid artwork (a direct Figma export, 1124 × 753 — the exact size of the `Blueprint`
//  group, 889:121), so this view only positions step number, media and instructions
//  over it rather than drawing the scroll shape itself.
//

import SwiftUI

struct BlueprintSheetView: View {

    let step: BlueprintStep

    /// Exposed so `BlueprintView` can align the title above to the same width.
    static let width: CGFloat = Metric.width

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let width: CGFloat = 1124
        static let height: CGFloat = 753
        static let stepNumberTop: CGFloat = 30
        static let stepNumberTrailing: CGFloat = 60
        static let mediaWidthFraction: CGFloat = 0.32
        static let contentHorizontalInset: CGFloat = 90
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image("blueprint_bg")
                .resizable()
                .frame(width: Metric.width * scale, height: Metric.height * scale)

            BlueprintStepNumber(text: step.stepLabel)
                .padding(.top, Metric.stepNumberTop * scale)
                .padding(.trailing, Metric.stepNumberTrailing * scale)

            content
        }
        .frame(width: Metric.width * scale, height: Metric.height * scale)
    }

    private var content: some View {
        HStack(alignment: .center, spacing: AppSpacing.xl * scale) {
            BlueprintMediaView(media: step.media)
                .frame(width: Metric.width * Metric.mediaWidthFraction * scale)
            BlueprintInstructionList(instructions: step.instructions)
        }
        .padding(.horizontal, Metric.contentHorizontalInset * scale)
    }
}

#Preview {
    BlueprintSheetView(step: BlueprintScript.steps[1])
        .previewBackdrop(.cameraFeed)
}
