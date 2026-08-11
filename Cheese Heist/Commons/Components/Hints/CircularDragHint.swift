//
//  CircularDragHint.swift
//  Cheese Heist
//
//  The crank demonstration, shown during the teaching beat before the joystick itself
//  appears.
//
//  It draws the ring AS WELL AS the arrow, at the joystick's own size and in its own
//  corner, so what the child is shown and what they are then handed are the same object.
//  This used to be an 80-point arc floating over an empty corner: it read as decoration
//  rather than as a preview of a control, and nothing about it said which way to turn.
//

import SwiftUI

struct CircularDragHint: View {

    /// Matches `CircularJoystickView`'s ring, so the demo sits exactly where the control
    /// will be.
    var diameter: CGFloat = 200

    @State private var isBreathing = false

    private enum Metric {
        /// The ring is a GHOST of the real control — present enough to be recognised,
        /// faint enough that the arrow is the thing being looked at.
        static let ghostRing: Double = 0.45
        static let breathe: CGFloat = 0.04
    }

    var body: some View {
        ZStack {
            // The spotlight cuts a HOLE at the joystick, so the one place the scrim is
            // not darkening the camera feed is exactly where this is drawn.
            ControlPlate(diameter: diameter)

            Circle()
                .strokeBorder(
                    AppColor.textOnCamera.opacity(Metric.ghostRing),
                    lineWidth: AppStroke.control
                )

            CrankDirectionGuide(diameter: diameter)
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(isBreathing ? 1 + Metric.breathe : 1 - Metric.breathe)
        .onAppear {
            withAnimation(.easeInOut(duration: AppDuration.transition * 3)
                .repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }
}

#Preview {
    CircularDragHint()
        .previewBackdrop(.cameraFeed)
}
