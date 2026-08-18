//
//  SuccessActionsRow.swift
//  Cheese Heist
//
//  PRD-Level1 §3 Phase 12: Retry (bottom-left) + Next (bottom-right), plus Home
//  (top-left, HIG exit placement) for returning to level select.
//
//  ═══ CORNERS, NOT THE MIDDLE OF THE SCREEN. ═══
//
//  This row carries its own insets and its own top/bottom alignment because the frame
//  puts each control in a corner and `SuccessOverlay` stacks it over a full-screen
//  scrim, where "just lay it out" means vertically centred — which is where the buttons
//  were landing, one on each side of the mouse's head.
//
//  Home stays top-left whether or not Next is shown — it lives in its own corner, not
//  the bottom row, so Level 2 (no Next) never needs to reposition it.
//

import SwiftUI

struct SuccessActionsRow: View {

    let onRetry: () -> Void
    let onHome: () -> Void
    var onNext: (() -> Void)?
    var showNext: Bool = true

    @Environment(\.layoutScale) private var scale

    /// Figma 800:197, at the 1366 × 1024 design scale.
    private enum Metric {
        static let sideInset: CGFloat = 86
        static let topInset: CGFloat = 88
        static let bottomInset: CGFloat = 88
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            LargeCTAButton(icon: .home, size: .celebration, tint: .mainBlue, action: onHome)
                .padding(.leading, Metric.sideInset * scale)
                .padding(.top, Metric.topInset * scale)

            HStack {
                LargeCTAButton(icon: .retry, size: .celebration, tint: .secondaryYellow, action: onRetry)
                Spacer()
                if showNext, let onNext {
                    LargeCTAButton(icon: .next, size: .celebration, action: onNext)
                }
            }
            .padding(.horizontal, Metric.sideInset * scale)
            .padding(.bottom, Metric.bottomInset * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

#Preview {
    SuccessActionsRow(onRetry: {}, onHome: {}, onNext: {})
        .previewBackdrop(.cameraFeed)
}
