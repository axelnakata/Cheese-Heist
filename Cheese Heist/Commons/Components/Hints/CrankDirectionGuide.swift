//
//  CrankDirectionGuide.swift
//  Cheese Heist
//
//  The animated arrow that circles the crank, saying which way round to turn it.
//
//  It runs CONTINUOUSLY while the joystick is on screen, not only during the tutorial
//  beat. The beat is over in a few seconds and the free run is not, and a child who
//  comes back to the crank three minutes later has no way back to the instruction.
//
//  ═══ IT NEVER TURNS RED ANY MORE. ═══
//
//  It used to flash red and speed up when the child cranked backwards. That has been
//  replaced by `CrankRatchet`, which stops the knob moving backwards at all — the crank
//  refuses rather than complaining, so there is no wrong state left to colour. What is
//  left here is one job: showing which way round to turn, slowly enough to be followed.
//

import SwiftUI

struct CrankDirectionGuide: View {

    var diameter: CGFloat
    var engagement: CrankEngagement = .disengaged

    @State private var lead: CGFloat = 0

    private enum Metric {
        /// Seconds per revolution. A demonstration, not a race: at 1.8s this outran any
        /// speed a child would actually turn the crank, and an arrow moving faster than
        /// the hand it is instructing reads as decoration rather than as a rate.
        static let revolution: Double = 3.4
        /// Faded, not hidden, once they are cranking correctly: still legible if they
        /// pause, not competing with the thing it was pointing at.
        static let engagedOpacity: Double = 0.4
    }

    var body: some View {
        CrankArrowShape(lead: lead)
            .fill(AppColor.accent)
            .frame(width: diameter, height: diameter)
            .opacity(engagement == .engaged ? Metric.engagedOpacity : 1)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(
                    .linear(duration: Metric.revolution).repeatForever(autoreverses: false)
                ) {
                    lead = 1
                }
            }
    }
}

#Preview("Turn this way") {
    CrankDirectionGuide(diameter: 200)
        .previewBackdrop(.cameraFeed)
}

#Preview("Cranking") {
    CrankDirectionGuide(diameter: 200, engagement: .engaged)
        .previewBackdrop(.cameraFeed)
}
