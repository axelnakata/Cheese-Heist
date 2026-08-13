//
//  CheeseCountdownRow.swift
//  Cheese Heist
//
//  PRD-Level2 §6.4 — three cheese icons in the HUD that transition from solid to
//  outline as time thresholds are crossed.
//
//  Compact layout — smaller than the success screen's `CheeseStarRow` at ~60pt per
//  wedge, not 144pt.
//

import SwiftUI

struct CheeseCountdownRow: View {

    /// How many cheese are still solid (0–3).
    let solidCount: Int

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let wedgeSize: CGFloat = 50
        static let wedgeGap: CGFloat = 4
    }

    var body: some View {
        HStack(spacing: Metric.wedgeGap * scale) {
            ForEach(0..<3, id: \.self) { index in
                Image(CheeseStarRow.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metric.wedgeSize * scale, height: Metric.wedgeSize * scale)
                    .opacity(index < solidCount ? 1.0 : 0.25)
                    .overlay(
                        index >= solidCount
                            ? RoundedRectangle(cornerRadius: 4 * scale)
                                .strokeBorder(AppColor.accent, lineWidth: 2 * scale)
                                .opacity(0.6)
                            : nil
                    )
                    .animation(
                        .easeInOut(duration: AppDuration.transition),
                        value: solidCount
                    )
            }
        }
    }
}

#Preview("All solid") {
    CheeseCountdownRow(solidCount: 3)
        .padding()
        .previewBackdrop(.cameraFeed)
}

#Preview("Two solid") {
    CheeseCountdownRow(solidCount: 2)
        .padding()
        .previewBackdrop(.cameraFeed)
}

#Preview("One solid") {
    CheeseCountdownRow(solidCount: 1)
        .padding()
        .previewBackdrop(.cameraFeed)
}

#Preview("None solid") {
    CheeseCountdownRow(solidCount: 0)
        .padding()
        .previewBackdrop(.cameraFeed)
}
