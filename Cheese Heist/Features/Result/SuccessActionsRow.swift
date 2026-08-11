//
//  SuccessActionsRow.swift
//  Cheese Heist
//
//  PRD-Level1 §3 Phase 12: Retry (bottom-left) + Next (bottom-right).
//
//  ═══ BOTTOM CORNERS, NOT THE MIDDLE OF THE SCREEN. ═══
//
//  This row carries its own insets and its own bottom alignment because the frame puts
//  it in the corners and `SuccessOverlay` stacks it over a full-screen scrim, where
//  "just lay it out" means vertically centred — which is where the two buttons were
//  landing, one on each side of the mouse's head.
//

import SwiftUI

struct SuccessActionsRow: View {

    let onRetry: () -> Void
    let onNext: () -> Void

    @Environment(\.layoutScale) private var scale

    /// Figma 800:197, at the 1366 × 1024 design scale.
    private enum Metric {
        static let sideInset: CGFloat = 86
        static let bottomInset: CGFloat = 88
    }

    var body: some View {
        HStack {
            LargeCTAButton(icon: .retry, size: .celebration, action: onRetry)
            Spacer()
            LargeCTAButton(icon: .next, size: .celebration, action: onNext)
        }
        .padding(.horizontal, Metric.sideInset * scale)
        .padding(.bottom, Metric.bottomInset * scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}

#Preview {
    SuccessActionsRow(onRetry: {}, onNext: {})
        .previewBackdrop(.cameraFeed)
}
