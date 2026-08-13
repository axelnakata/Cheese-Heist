//
//  Level2HUDLayer.swift
//  Cheese Heist
//
//  PRD-Level2 §6.1 — the persistent HUD furniture for Level 2:
//    • Timer badge (top-right)
//    • Cheese countdown icons (top-right, left of timer)
//    • Restart button (top-left)
//    • Instruction chip (top-centre, during selection only)
//    • Role labels on gears
//

import SwiftUI

struct Level2HUDLayer: View {

    let chip: String?
    let targets: [GearScreenTarget]
    let showsRoleLabels: Bool
    let showsTimer: Bool
    let timerSeconds: Int
    let showsCheeseCountdown: Bool
    let solidCheeseCount: Int
    let showsRestart: Bool
    let onRestart: () -> Void

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let cornerInset: CGFloat = 64
        static let topInset: CGFloat = 48
        static let timerCheeseGap: CGFloat = 12
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if showsRoleLabels {
                GearRoleLabelLayer(targets: targets)
            }

            // Top-left: restart button
            if showsRestart {
                VStack {
                    HStack {
                        LargeCTAButton(icon: .retry, size: .standard, action: onRestart)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(Metric.cornerInset * scale)
            }

            // Top-right: cheese + timer
            VStack {
                HStack {
                    Spacer()
                    if showsCheeseCountdown {
                        CheeseCountdownRow(solidCount: solidCheeseCount)
                            .transition(.opacity)
                    }
                    if showsTimer {
                        TimerBadge(seconds: timerSeconds)
                    }
                }
                Spacer()
            }
            .padding(.trailing, Metric.cornerInset * scale)
            .padding(.top, Metric.topInset * scale)

            // Centre: instruction chip
            if let chip {
                VStack {
                    InstructionChip(chip)
                        .padding(.top, AppSpacing.xl * scale)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview("Selecting Roles") {
    Level2HUDLayer(
        chip: Level2Script.selectingRoles,
        targets: [],
        showsRoleLabels: false,
        showsTimer: true,
        timerSeconds: 15,
        showsCheeseCountdown: false,
        solidCheeseCount: 3,
        showsRestart: false,
        onRestart: {}
    )
    .previewBackdrop(.cameraFeed)
}

#Preview("Cranking") {
    Level2HUDLayer(
        chip: nil,
        targets: [],
        showsRoleLabels: true,
        showsTimer: true,
        timerSeconds: 8,
        showsCheeseCountdown: true,
        solidCheeseCount: 2,
        showsRestart: true,
        onRestart: {}
    )
    .previewBackdrop(.cameraFeed)
}
