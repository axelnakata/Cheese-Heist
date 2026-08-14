//
//  Level1HUDLayer.swift
//  Cheese Heist
//
//  The persistent furniture: the instruction chip at the top, the role labels on their
//  leader lines, and the joystick in the bottom-right corner once it is live.
//

import SwiftUI

struct Level1HUDLayer: View {

    let chip: String?
    let targets: [GearScreenTarget]
    let gate: Level1InputGate
    let showsRoleLabels: Bool
    var engagement: CrankEngagement = .disengaged
    let onDrag: (CGPoint, CGPoint) -> Void
    let onRelease: () -> Void

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let cornerInset: CGFloat = 64
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if showsRoleLabels {
                GearRoleLabelLayer(targets: targets)
            }

            VStack {
                Spacer()
                if let chip {
                    InstructionChip(chip)
                        .padding(.bottom, AppSpacing.xl * scale)
                }
            }
            .frame(maxWidth: .infinity)

            corner
        }
    }

    @ViewBuilder
    private var corner: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if gate.joystickEnabled {
                    CircularJoystickView(
                        isEnabled: true, engagement: engagement,
                        onDrag: onDrag, onRelease: onRelease
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(Metric.cornerInset * scale)
    }
}

#Preview {
    Level1HUDLayer(
        chip: Level1Script.selectingRoles,
        targets: [],
        gate: .of(.selectingRoles),
        showsRoleLabels: false,
        onDrag: { _, _ in },
        onRelease: {}
    )
    .previewBackdrop(.cameraFeed)
}
