//
//  GearAttributeBar.swift
//  Cheese Heist
//
//  PRD-Level2 §6.3 — a single segmented bar with 3 cells.
//  Each cell is a rounded rectangle. Filled cells use `fillColor`;
//  unfilled cells use a white border with clear fill.
//

import SwiftUI

struct GearAttributeBar: View {

    /// How many segments are filled (1–3). Clamped internally.
    let filledCount: Int

    /// The colour for filled segments.
    let fillColor: Color

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let segmentWidth: CGFloat = 100
        static let segmentHeight: CGFloat = 28
        static let segmentGap: CGFloat = 6
        static let segmentRadius: CGFloat = 6
        static let borderWidth: CGFloat = 2
    }

    private var clamped: Int { max(0, min(3, filledCount)) }

    var body: some View {
        HStack(spacing: Metric.segmentGap * scale) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: Metric.segmentRadius * scale)
                    .fill(index < clamped ? fillColor : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: Metric.segmentRadius * scale)
                            .strokeBorder(
                                index < clamped ? fillColor : Color.white.opacity(0.5),
                                lineWidth: Metric.borderWidth * scale
                            )
                    )
                    .frame(
                        width: Metric.segmentWidth * scale,
                        height: Metric.segmentHeight * scale
                    )
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        GearAttributeBar(filledCount: 1, fillColor: .red)
        GearAttributeBar(filledCount: 2, fillColor: .yellow)
        GearAttributeBar(filledCount: 3, fillColor: .green)
    }
    .padding()
    .previewBackdrop(.cameraFeed)
}
