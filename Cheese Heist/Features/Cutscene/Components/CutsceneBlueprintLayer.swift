//
//  CutsceneBlueprintLayer.swift
//  Cheese Heist
//
//  PRD-Cutscene §6.4 — the scrim + glowing blueprint, tappable only in beat 6.
//  From `Docs/cutscene frames/cutscene 6.png`: the screen dims, the blueprint scroll
//  sits centre-stage with its glow, and the tap target is the blueprint itself.
//

import SwiftUI

struct CutsceneBlueprintLayer: View {

    let onTap: () -> Void

    @Environment(\.layoutScale) private var scale
    @State private var hasEntered = false

    var body: some View {
        ZStack {
            ScrimOverlay()
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)

            BlueprintScrollView()
                .onTapGesture(perform: onTap)
        }
        .opacity(hasEntered ? 1 : 0)
        .scaleEffect(hasEntered ? 1 : 0.92)
        .onAppear {
            withAnimation(.easeOut(duration: AppDuration.transition)) {
                hasEntered = true
            }
        }
    }
}

#Preview {
    CutsceneBlueprintLayer(onTap: {})
        .previewBackdrop(.cameraFeed)
}
