//
//  GearAttributeBarPair.swift
//  Cheese Heist
//
//  PRD-Level2 §6.3 — strength and speed bars stacked vertically with icons and labels.
//
//  Layout:
//    [🦾 icon] [████|████|    ] [💪 icon]
//    weak                       strong
//
//    [🐢 icon] [████|    |    ] [🐇 icon]
//    slow                       fast
//

import SwiftUI

struct GearAttributeBarPair: View {

    let strengthLevel: Int
    let speedLevel: Int

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let iconWidth: CGFloat = 32
        static let iconHeight: CGFloat = 24
        static let labelGap: CGFloat = 4
        static let columnWidth: CGFloat = 48
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
        VStack(spacing: Metric.labelGap * scale) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(
                    width: Metric.iconWidth * scale,
                    height: Metric.iconHeight * scale,
                    alignment: .bottom
                )
            Text(text)
                .appText(AppFont.caption)
                .foregroundStyle(AppColor.textOnCamera)
        }
        .frame(width: Metric.columnWidth * scale)
    }

    /// Strength bar colour: red at 1/3, green at 2+/3.
    private var strengthColor: Color {
        strengthLevel <= 1 ? AppColor.stateInvalid : AppColor.stateValid
    }

    /// Speed bar colour: red at 1/3, amber at 2/3, green at 3/3.
    private var speedColor: Color {
        if speedLevel <= 1 { return AppColor.stateInvalid }
        if speedLevel == 2 { return AppColor.stateCaution }
        return AppColor.stateValid
    }
}

#Preview("Strong & Slow") {
    GearAttributeBarPair(strengthLevel: 3, speedLevel: 1)
        .padding()
        .previewBackdrop(.cameraFeed)
}

#Preview("Weak & Fast") {
    GearAttributeBarPair(strengthLevel: 1, speedLevel: 3)
        .padding()
        .previewBackdrop(.cameraFeed)
}

#Preview("Balanced") {
    GearAttributeBarPair(strengthLevel: 2, speedLevel: 2)
        .padding()
        .previewBackdrop(.cameraFeed)
}
