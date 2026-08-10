//
//  InstructionChip.swift
//  Cheese Heist
//
//  PRD §7.6 — Figma 639:142. Height 90, radius .chip, 60 % navy fill, parchment 1.5
//  stroke, .title text, 25 h / 30 v padding. Multi-line for the surface-scan guideline.
//

import SwiftUI

struct InstructionChip: View {

    private enum Metric {
        static let minHeight: CGFloat = 90
        static let horizontalPadding: CGFloat = 25
        static let verticalPadding: CGFloat = 30
        static let lineSpacing: CGFloat = 4
    }

    let lines: [String]

    @Environment(\.layoutScale) private var scale

    init(_ lines: [String]) {
        self.lines = lines
    }

    init(_ line: String) {
        self.lines = [line]
    }

    var body: some View {
        VStack(spacing: Metric.lineSpacing * scale) {
            ForEach(lines, id: \.self) { line in
                Text(line).appText(AppFont.title)
            }
        }
        .foregroundStyle(AppColor.textOnCamera)
        .multilineTextAlignment(.center)
        .padding(.horizontal, Metric.horizontalPadding * scale)
        .padding(.vertical, Metric.verticalPadding * scale)
        .frame(minHeight: Metric.minHeight * scale)
        .background(chipShape.fill(AppGradient.navyChip))
        .overlay(chipShape.strokeBorder(AppColor.strokeChip, lineWidth: AppStroke.chip * scale))
    }

    private var chipShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AppRadius.chip * scale, style: .continuous)
    }
}

#Preview("Single + multi-line — camera feed") {
    VStack(spacing: AppSpacing.l) {
        InstructionChip("Looking at your gears…")
        InstructionChip(["Find a flat surface.", "Tap on the green circle to start!"])
        InstructionChip("Tap one of the gear to set it as a driver")
    }
    .previewBackdrop(.cameraFeed)
}

#Preview("On parchment") {
    InstructionChip("Look for a flat surface!")
        .previewBackdrop(.parchment)
}
