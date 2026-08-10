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

import SwiftUI

struct CircularJoystickView: View {

    let isEnabled: Bool
    let onDrag: (CGPoint, CGPoint) -> Void
    let onRelease: () -> Void

    @Environment(\.layoutScale) private var scale
    @State private var knobAngle: Angle = .degrees(90)

    private enum Metric {
        static let ring: CGFloat = 200
        static let knob: CGFloat = 62
        static let thumb: CGFloat = 58
        static let stroke: CGFloat = 5
    }

    var body: some View {
        let size = Metric.ring * scale

        ZStack {
            CircularJoystickRingShape(lineWidth: Metric.stroke * scale)
                .stroke(AppColor.textOnCamera, lineWidth: Metric.stroke * scale)

            knob(size: size)
            thumb(size: size)
        }
        .frame(width: size, height: size)
        .contentShape(Circle().inset(by: -Metric.knob * scale / 2))
        .gesture(drag(in: size))
        .opacity(isEnabled ? 1 : 0.45)
        .allowsHitTesting(isEnabled)
    }

    /// The pale disc that sits under the finger.
    private func knob(size: CGFloat) -> some View {
        Circle()
            .fill(AppColor.textOnCamera.opacity(0.75))
            .frame(width: Metric.knob * scale, height: Metric.knob * scale)
            .offset(offset(for: knobAngle, radius: size / 2))
    }

    /// The role-coloured dot that shows how far round the ring the crank has come.
    private func thumb(size: CGFloat) -> some View {
        Circle()
            .fill(AppColor.roleDriver.opacity(0.85))
            .frame(width: Metric.thumb * scale, height: Metric.thumb * scale)
            .offset(offset(for: knobAngle - .degrees(70), radius: size / 2))
    }

    private func offset(for angle: Angle, radius: CGFloat) -> CGSize {
        CGSize(width: cos(angle.radians) * radius, height: sin(angle.radians) * radius)
    }

    private func drag(in size: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let centre = CGPoint(x: size / 2, y: size / 2)
                knobAngle = Angle(radians: atan2(
                    value.location.y - centre.y, value.location.x - centre.x
                ))
                onDrag(value.location, centre)
            }
            .onEnded { _ in onRelease() }
    }
}

#Preview {
    CircularJoystickView(isEnabled: true, onDrag: { _, _ in }, onRelease: {})
        .previewBackdrop(.cameraFeed)
}
