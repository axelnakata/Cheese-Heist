//
//  TimerBadge.swift
//  Cheese Heist
//
//  PRD-Level2 §6.2 — rounded rectangle badge showing the countdown seconds.
//  Same visual language as the instruction chip: navy background, white text — until
//  the timer starts, at which point the fill tracks the star zone it's warning about.
//

import SwiftUI

struct TimerBadge: View {

    /// Seconds remaining.
    let seconds: Int

    /// Whether the countdown has started. Idle (pre-joystick-engagement) always shows
    /// the neutral navy fill, matching the design's "15s" resting state.
    let isRunning: Bool

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let width: CGFloat = 96
        static let height: CGFloat = 64
        static let cornerRadius: CGFloat = 20
        static let borderWidth: CGFloat = 2
    }

    /// Idle → neutral navy. Running → green (3★ still reachable, ≥10s), amber (2★ zone,
    /// 5–9s), red (1★ zone, 1–4s — about to fail-slow). A pure function, not a computed
    /// property, so it's testable without instantiating SwiftUI.
    static func fill(seconds: Int, isRunning: Bool) -> Color {
        guard isRunning else { return AppColor.surfaceInstruction }
        if seconds >= 10 { return AppColor.stateValid }
        if seconds >= 5 { return AppColor.stateCaution }
        return AppColor.stateInvalid
    }

    var body: some View {
        Text("\(seconds)s")
            .appText(AppFont.title)
            .foregroundStyle(AppColor.textOnCamera)
            .frame(width: Metric.width * scale, height: Metric.height * scale)
            .background(
                RoundedRectangle(cornerRadius: Metric.cornerRadius * scale)
                    .fill(Self.fill(seconds: seconds, isRunning: isRunning))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metric.cornerRadius * scale)
                    .strokeBorder(Color.white, lineWidth: Metric.borderWidth * scale)
            )
    }
}

#Preview {
    HStack(spacing: 20) {
        TimerBadge(seconds: 15, isRunning: false)
        TimerBadge(seconds: 12, isRunning: true)
        TimerBadge(seconds: 7, isRunning: true)
        TimerBadge(seconds: 2, isRunning: true)
    }
    .padding()
    .previewBackdrop(.cameraFeed)
}
