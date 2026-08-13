//
//  TimerBadge.swift
//  Cheese Heist
//
//  PRD-Level2 §6.2 — rounded rectangle badge showing the countdown seconds.
//  Same visual language as the instruction chip: navy background, white text.
//

import SwiftUI

struct TimerBadge: View {

    /// Seconds remaining.
    let seconds: Int

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let width: CGFloat = 68
        static let height: CGFloat = 48
        static let cornerRadius: CGFloat = 14
    }

    var body: some View {
        Text("\(seconds)s")
            .appText(AppFont.title)
            .foregroundStyle(AppColor.textOnCamera)
            .frame(width: Metric.width * scale, height: Metric.height * scale)
            .background(
                RoundedRectangle(cornerRadius: Metric.cornerRadius * scale)
                    .fill(AppColor.surfaceInstruction)
            )
    }
}

#Preview {
    HStack(spacing: 20) {
        TimerBadge(seconds: 15)
        TimerBadge(seconds: 7)
        TimerBadge(seconds: 0)
    }
    .padding()
    .previewBackdrop(.cameraFeed)
}
