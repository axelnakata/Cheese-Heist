//
//  CrankDirectionGuide.swift
//  Cheese Heist
//
//  Three animations sharing one spot beside the knob, one per `CrankHint`. Never more
//  than one at once, and never while the child is actually cranking correctly — a hint
//  competing with the thing it is teaching just becomes noise.
//
//  ═══ WHY RED CAME BACK. ═══
//
//  It used to never turn red: `CrankRatchet` stopped the knob moving backwards at all,
//  so a wrong turn did nothing and there was nothing to warn about. That is no longer
//  true — turning backwards now lets the rope fall, so a wrong turn has a consequence
//  again, and `.wrongWay` gets its own alert back: the same arrow, tinted
//  `AppColor.stateInvalid` and shaking rather than calmly sweeping.
//
//  ═══ WHY IT NOW HIDES WHILE PLAYING. ═══
//
//  It used to run continuously, fading only while cranking correctly, on the theory
//  that a child who came back to the crank minutes later still needed reminding. In
//  practice a hint faded to 40% is still visible the entire time the child is
//  successfully doing the right thing, which reads as the app nagging. `.idle` (and
//  `.wrongWay`, `.falling`) only ever apply while `isPressed` is false or the turn is
//  actively wrong — see `CrankHint.of`.
//

import SwiftUI

struct CrankDirectionGuide: View {

    var diameter: CGFloat
    var hint: CrankHint = .idle

    @State private var lead: CGFloat = 0
    @State private var wobble = false

    private enum Metric {
        /// Seconds per revolution while idle. A demonstration, not a race: at 1.8s
        /// this outran any speed a child would actually turn the crank.
        static let idleRevolution: Double = 3.4
        /// Faster while alerting a wrong turn — urgency, not decoration.
        static let alertRevolution: Double = 1.6
        static let wobbleAngle: Angle = .degrees(7)
        static let wobbleDuration: Double = 0.13
        static let fallingIconFraction: CGFloat = 0.32
    }

    var body: some View {
        ZStack {
            switch hint {
            case .none:
                EmptyView()

            case .idle:
                arrow(tint: AppColor.accent)
                    .onAppear { startSweep(seconds: Metric.idleRevolution) }

            case .wrongWay:
                arrow(tint: AppColor.stateInvalid)
                    .rotationEffect(wobble ? Metric.wobbleAngle : -Metric.wobbleAngle)
                    .onAppear {
                        startSweep(seconds: Metric.alertRevolution)
                        withAnimation(.easeInOut(duration: Metric.wobbleDuration).repeatForever(autoreverses: true)) {
                            wobble = true
                        }
                    }

            case .falling:
                Image(systemName: "arrow.down.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: diameter * Metric.fallingIconFraction)
                    .foregroundStyle(AppColor.stateInvalid)
                    .symbolEffect(.bounce, options: .repeating)
            }
        }
        .frame(width: diameter, height: diameter)
        .allowsHitTesting(false)
    }

    private func arrow(tint: Color) -> some View {
        CrankArrowShape(lead: lead)
            .fill(tint)
    }

    private func startSweep(seconds: Double) {
        withAnimation(.linear(duration: seconds).repeatForever(autoreverses: false)) {
            lead = 1
        }
    }
}

#Preview("Turn this way") {
    CrankDirectionGuide(diameter: 200)
        .previewBackdrop(.cameraFeed)
}

#Preview("Cranking — no hint") {
    CrankDirectionGuide(diameter: 200, hint: .none)
        .previewBackdrop(.cameraFeed)
}

#Preview("Wrong way") {
    CrankDirectionGuide(diameter: 200, hint: .wrongWay)
        .previewBackdrop(.cameraFeed)
}

#Preview("Falling") {
    CrankDirectionGuide(diameter: 200, hint: .falling)
        .previewBackdrop(.cameraFeed)
}
