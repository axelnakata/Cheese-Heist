// GearDetectingLayer.swift — Cheese Heist
// PRD-Level1 §3 Phase 2: "Looking at your gears…" chip.

import SwiftUI

struct GearDetectingLayer: View {

    @Environment(\.layoutScale) private var scale

    var body: some View {
        VStack {
            Spacer()
            InstructionChip("Looking at your gears…")
                .padding(.bottom, AppSpacing.xxl * scale)
        }
    }
}

#Preview {
    GearDetectingLayer()
        .previewBackdrop(.cameraFeed)
}
