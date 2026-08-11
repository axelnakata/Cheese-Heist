//
//  Level1HUDLayer.swift
//  Cheese Heist
//
//  The persistent furniture: the instruction chip at the top, the role labels on their
//  leader lines, and whichever of PULL or the joystick belongs in the bottom-right
//  corner right now.
//
//  D-2 is a layout fact here: the two controls occupy the SAME corner and never share
//  it, so tapping PULL reads as the button turning into the crank.
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
    let onPull: () -> Void

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
                if let chip {
                    InstructionChip(chip)
                        .padding(.top, AppSpacing.xl * scale)
                }
                Spacer()
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
                if gate.pullVisible {
                    PullButton(action: onPull)
                        .transition(.scale.combined(with: .opacity))
                } else if gate.joystickEnabled {
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
        chip: Level1Script.handOver,
        targets: [],
        gate: .of(.selectingRoles),
        showsRoleLabels: false,
        onDrag: { _, _ in },
        onRelease: {},
        onPull: {}
    )
    .previewBackdrop(.cameraFeed)
}
