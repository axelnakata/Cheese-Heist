//
//  Level2PlayingLayer.swift
//  Cheese Heist
//
//  PRD-Level2 §6 — the bottom overlay during the cranking phase:
//    • Strength/speed bar pair (bottom-centre-left)
//    • Joystick (bottom-right)
//

import SwiftUI

struct Level2PlayingLayer: View {

    let showsBars: Bool
    let strengthLevel: Int
    let speedLevel: Int
    let joystickEnabled: Bool
    var engagement: CrankEngagement = .disengaged
    let onDrag: (CGPoint, CGPoint) -> Void
    let onRelease: () -> Void

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let cornerInset: CGFloat = 64
        static let barBottomInset: CGFloat = 48
    }

    var body: some View {
        ZStack {
            // Bottom: bars + joystick
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    if showsBars {
                        GearAttributeBarPair(
                            strengthLevel: strengthLevel,
                            speedLevel: speedLevel
                        )
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer()

                    if joystickEnabled {
                        CircularJoystickView(
                            isEnabled: true, engagement: engagement,
                            onDrag: onDrag, onRelease: onRelease
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, Metric.cornerInset * scale)
                .padding(.bottom, Metric.barBottomInset * scale)
            }
        }
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
