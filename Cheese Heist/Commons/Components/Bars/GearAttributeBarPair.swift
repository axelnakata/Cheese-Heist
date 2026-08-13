//
//  GearAttributeBarPair.swift
//  Cheese Heist
//
//  PRD-Level2 §6.3 — strength and speed bars stacked vertically with icons and labels.
//
//  Layout:
//    [🦾 icon] [████|████|████|    ] [💪 icon]
//    weak                            strong
//
//    [🐢 icon] [████|████|    |    ] [🐇 icon]
//    slow                            fast
//

import SwiftUI

struct GearAttributeBarPair: View {

    let strengthLevel: Int
    let speedLevel: Int

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let iconSize: CGFloat = 32
        static let iconGap: CGFloat = 8
        static let rowGap: CGFloat = 8
    }

    var body: some View {
        VStack(spacing: Metric.rowGap * scale) {
            strengthRow
            speedRow
        }
    }

    private var strengthRow: some View {
        HStack(spacing: Metric.iconGap * scale) {
            iconLabel(icon: "weak_icon", text: "weak")
            GearAttributeBar(filledCount: strengthLevel, fillColor: strengthColor)
            iconLabel(icon: "strong_icon", text: "strong")
        }
    }

    private var speedRow: some View {
        HStack(spacing: Metric.iconGap * scale) {
            iconLabel(icon: "slow_icon", text: "slow")
            GearAttributeBar(filledCount: speedLevel, fillColor: speedColor)
            iconLabel(icon: "fast_icon", text: "fast")
        }
    }

    private func iconLabel(icon: String, text: String) -> some View {
        VStack(spacing: 2 * scale) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: Metric.iconSize * scale, height: Metric.iconSize * scale)
            Text(text)
                .appText(AppFont.caption)
                .foregroundStyle(AppColor.textOnCamera)
        }
    }

    /// Strength bar colour: red at 1/4, green at 2+/4.
    private var strengthColor: Color {
        strengthLevel <= 1 ? AppColor.stateInvalid : AppColor.stateValid
    }

    /// Speed bar colour: red at 1/4, amber at 2/4, green at 3+/4.
    private var speedColor: Color {
        if speedLevel <= 1 { return AppColor.stateInvalid }
        if speedLevel <= 2 { return AppColor.accent }
        return AppColor.stateValid
    }
}

#Preview("Strong & Slow") {
    GearAttributeBarPair(strengthLevel: 4, speedLevel: 1)
        .padding()
        .previewBackdrop(.cameraFeed)
}

#Preview("Weak & Fast") {
    GearAttributeBarPair(strengthLevel: 1, speedLevel: 4)
        .padding()
        .previewBackdrop(.cameraFeed)
}

#Preview("Balanced") {
    GearAttributeBarPair(strengthLevel: 2, speedLevel: 3)
        .padding()
        .previewBackdrop(.cameraFeed)
}
