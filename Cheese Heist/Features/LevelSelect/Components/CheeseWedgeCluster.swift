//
//  CheeseWedgeCluster.swift
//  Cheese Heist
//
//  Figma "cheese star-02" instances (1021:275, 1031:177-181) — three of the existing
//  `cheese_star` wedges fanned out under an unlocked path stop. Reuses the asset the
//  success screen already ships rather than importing a near-duplicate.
//

import SwiftUI

struct CheeseWedgeCluster: View {

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let wedgeSide: CGFloat = 95
        static let overlap: CGFloat = 24
        static let rotations: [Angle] = [.degrees(-14), .degrees(4), .degrees(16)]
        static let verticalOffsets: [CGFloat] = [5, -8, 8]
    }

    var body: some View {
        HStack(spacing: -Metric.overlap * scale) {
            ForEach(0..<3, id: \.self) { index in
                Image(CheeseStarRow.assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Metric.wedgeSide * scale, height: Metric.wedgeSide * scale)
                    .rotationEffect(Metric.rotations[index])
                    .offset(y: Metric.verticalOffsets[index] * scale)
            }
        }
    }
}

#Preview {
    CheeseWedgeCluster()
        .previewBackdrop(.parchment)
}
