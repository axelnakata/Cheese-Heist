// CheeseStarRow.swift — Cheese Heist
// PRD-Level1 §3 Phase 12: three cheese-star images on the success screen.
// Uses cheese-star.svg from Figma assets.

import SwiftUI

struct CheeseStarRow: View {

    @Environment(\.layoutScale) private var scale

    @State private var showStars = [false, false, false]

    var body: some View {
        HStack(spacing: AppSpacing.m * scale) {
            ForEach(0..<3, id: \.self) { index in
                Image("cheese-star")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: starSize(for: index), height: starSize(for: index))
                    .scaleEffect(showStars[index] ? 1.0 : 0.0)
                    .opacity(showStars[index] ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.6)
                        .delay(Double(index) * 0.2),
                        value: showStars[index]
                    )
            }
        }
        .onAppear { animateStars() }
    }

    private func starSize(for index: Int) -> CGFloat {
        let sizes: [CGFloat] = [60, 80, 60]
        return sizes[index] * scale
    }

    private func animateStars() {
        for starIndex in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(starIndex) * 0.2) {
                showStars[starIndex] = true
            }
        }
    }
}

#Preview {
    CheeseStarRow()
        .previewBackdrop(.cameraFeed)
}
