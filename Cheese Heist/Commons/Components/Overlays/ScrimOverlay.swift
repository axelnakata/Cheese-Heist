// ScrimOverlay.swift — Cheese Heist
// PRD §7.6 — dim background at `surfaceScrim` opacity.

import SwiftUI

struct ScrimOverlay: View {
    var body: some View {
        AppColor.surfaceScrim
            .ignoresSafeArea()
    }
}

#Preview {
    ScrimOverlay()
}
