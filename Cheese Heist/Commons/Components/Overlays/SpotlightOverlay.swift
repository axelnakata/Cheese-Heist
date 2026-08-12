// SpotlightOverlay.swift — Cheese Heist
// PRD §7.6 — dim-with-hole for tutorial beats.

import SwiftUI

struct SpotlightOverlay: View {

    let target: SpotlightTarget

    var body: some View {
        SpotlightHoleShape(target: target)
            .fill(AppColor.surfaceScrim, style: FillStyle(eoFill: true))
            .ignoresSafeArea()
            .animation(.easeInOut(duration: AppDuration.transition), value: target)
    }
}

#Preview {
    SpotlightOverlay(
        target: SpotlightTarget(
            center: CGPoint(x: 200, y: 300),
            size: CGSize(width: 180, height: 180),
            cornerRadius: 90
        )
    )
}
