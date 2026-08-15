//
//  Level2PlayingLayer.swift
//  Cheese Heist
//
//  PRD-Level2 §6 / Figma 857:94 — the bottom overlay during the cranking phase:
//    • Strength/speed bar pair, on its own navy card, bottom-centre
//    • Joystick, bottom-right corner — independent of the card, so the card stays
//      centred instead of being pushed off-centre by the joystick sharing its row
//

import SwiftUI

struct Level2PlayingLayer: View {

    let showsBars: Bool
    let strengthLevel: Int
    let speedLevel: Int
    let joystickEnabled: Bool
    var hint: CrankHint = .idle
    let onDrag: (CGPoint, CGPoint) -> Void
    let onRelease: () -> Void

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let cornerInset: CGFloat = 64
        static let barBottomInset: CGFloat = 48
        static let cardHorizontalPadding: CGFloat = 28
        static let cardVerticalPadding: CGFloat = 20
    }

    var body: some View {
        ZStack {
            if showsBars {
                VStack {
                    Spacer()
                    GearAttributeBarPair(strengthLevel: strengthLevel, speedLevel: speedLevel)
                        .padding(.horizontal, Metric.cardHorizontalPadding * scale)
                        .padding(.vertical, Metric.cardVerticalPadding * scale)
                        .background(cardShape.fill(AppColor.surfaceInstruction))
                        .overlay(cardShape.strokeBorder(AppColor.strokeChip, lineWidth: AppStroke.chip * scale))
                        .padding(.bottom, Metric.barBottomInset * scale)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                .frame(maxWidth: .infinity)
            }

            if joystickEnabled {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        CircularJoystickView(
                            isEnabled: true, hint: hint,
                            onDrag: onDrag, onRelease: onRelease
                        )
                    }
                }
                .padding(Metric.cornerInset * scale)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AppRadius.chip * scale, style: .continuous)
    }
}

#Preview("Playing") {
    Level2PlayingLayer(
        showsBars: true,
        strengthLevel: 3,
        speedLevel: 2,
        joystickEnabled: true,
        onDrag: { _, _ in },
        onRelease: {}
    )
    .previewBackdrop(.cameraFeed)
}
