//
//  CircularJoystickView.swift
//  Cheese Heist
//
//  The crank. A white ring with a knob the child drags round it, bottom-right, exactly
//  where PULL was — D-2: PULL commits, the joystick cranks, and the two never share the
//  screen.
//
//  It reports POINTS, not decisions. `CircularDragTracker` turns them into an angular
//  velocity and `CrankInputViewModel` into an engagement, which is why the direction
//  logic is unit-tested and this file only draws.
//
//  ═══ THE BLUE DOT IS GONE. ═══
//
//  There used to be a second, role-coloured disc parked 70° behind the knob, meant to
//  read as "the crank has come this far round". In testing children turned the wrong
//  way, and this is why: a dot has no direction in it, and two dots on a ring read as
//  a pair of things rather than as motion. `CrankDirectionGuide` replaces it with a
//  moving arrow, which can only be read one way round.
//

import SwiftUI

struct CircularJoystickView: View {

    let isEnabled: Bool

    /// What the child is doing with it right now — the guide goes red on a wrong turn,
    /// which is the only feedback a wrong turn gets (PRD §6.5: it must not lower the
    /// cheese).
    var engagement: CrankEngagement = .disengaged

    let onDrag: (CGPoint, CGPoint) -> Void
    let onRelease: () -> Void

    @Environment(\.layoutScale) private var scale
    @State private var knobAngle: Angle = .degrees(90)

    private enum Metric {
        static let ring: CGFloat = 200
        static let knob: CGFloat = 62
        static let disabledOpacity: Double = 0.45
    }

    var body: some View {
        let size = Metric.ring * scale

        ZStack {
            ControlPlate(diameter: size)

            CircularJoystickRingShape(lineWidth: AppStroke.control * scale)
                .stroke(AppColor.textOnCamera, lineWidth: AppStroke.control * scale)

            CrankDirectionGuide(diameter: size, engagement: engagement)

            knob(size: size)
        }
        .frame(width: size, height: size)
        .contentShape(Circle().inset(by: -Metric.knob * scale / 2))
        .gesture(drag(in: size))
        .opacity(isEnabled ? 1 : Metric.disabledOpacity)
        .allowsHitTesting(isEnabled)
    }

    /// The pale disc that sits under the finger.
    private func knob(size: CGFloat) -> some View {
        Circle()
            .fill(AppColor.textOnCamera)
            .shadow(color: AppColor.controlShadow, radius: AppSpacing.xs * scale)
            .frame(width: Metric.knob * scale, height: Metric.knob * scale)
            .offset(offset(for: knobAngle, radius: size / 2))
    }

    private func offset(for angle: Angle, radius: CGFloat) -> CGSize {
        CGSize(width: cos(angle.radians) * radius, height: sin(angle.radians) * radius)
    }

    /// ═══ THE KNOB ONLY GOES ONE WAY. ═══
    ///
    /// It used to follow the finger wherever it went and the app merely COLOURED the
    /// backwards case red. A colour is a message about a thing that happened; a control
    /// that will not move is the thing not happening. Anticlockwise drags now leave the
    /// knob exactly where it is, so a child who tries it feels the crank refuse rather
    /// than reading a warning about it.
    ///
    /// `CircularDragTracker` still sees the raw points and still classifies direction —
    /// that is what keeps the CHEESE from moving. This is the half the child can feel.
    private func drag(in size: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let centre = CGPoint(x: size / 2, y: size / 2)
                let touch = Angle(radians: atan2(
                    value.location.y - centre.y, value.location.x - centre.x
                ))
                if CrankRatchet.advances(from: knobAngle, to: touch) { knobAngle = touch }
                onDrag(value.location, centre)
            }
            .onEnded { _ in onRelease() }
    }
}

#Preview("Idle") {
    CircularJoystickView(isEnabled: true, onDrag: { _, _ in }, onRelease: {})
        .previewBackdrop(.cameraFeed)
}

#Preview("Cranking") {
    CircularJoystickView(
        isEnabled: true, engagement: .engaged, onDrag: { _, _ in }, onRelease: {}
    )
    .previewBackdrop(.cameraFeed)
}

#Preview("Over a white desk") {
    CircularJoystickView(isEnabled: true, onDrag: { _, _ in }, onRelease: {})
        .previewBackdrop(.parchment)
}
