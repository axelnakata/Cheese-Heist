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
        static let width: CGFloat = 96
        static let height: CGFloat = 64
        static let cornerRadius: CGFloat = 20
        static let borderWidth: CGFloat = 2
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
            .overlay(
                RoundedRectangle(cornerRadius: Metric.cornerRadius * scale)
                    .strokeBorder(Color.white, lineWidth: Metric.borderWidth * scale)
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
