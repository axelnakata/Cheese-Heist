//
//  WrongGearCountIllustration.swift
//  Cheese Heist
//
//  The numbered gear-highlight illustration showing two gear positions on the crane.
//

import SwiftUI

struct WrongGearCountIllustration: View {

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let width: CGFloat = 600
        static let height: CGFloat = 500
        static let craneWidth: CGFloat = 600
        static let smallCircleDiameter: CGFloat = 50
        static let largeCircleDiameter: CGFloat = 120
        static let strokeWidth: CGFloat = 4
    }

    var body: some View {
        ZStack {
            Image("crane")
                .resizable()
                .scaledToFit()
                .frame(width: Metric.craneWidth * scale)

            gearHighlight(
                number: "1",
                diameter: Metric.smallCircleDiameter * scale,
                circleOffset: CGSize(width: 93 * scale, height: -127 * scale ),
                numberOffset: CGSize(width: 93 * scale, height: -80 * scale)
            )

            gearHighlight(
                number: "2",
                diameter: Metric.largeCircleDiameter * scale,
                circleOffset: CGSize(width: 182 * scale, height: -125 * scale),
                numberOffset: CGSize(width: 182 * scale, height: -40 * scale)
            )
        }
        .frame(width: Metric.width * scale, height: Metric.height * scale)
        .accessibilityLabel("Crane illustration with two highlighted gear positions")
    }

    // MARK: - Ring Highlight & Number Text
    private func gearHighlight(
        number: String,
        diameter: CGFloat,
        circleOffset: CGSize,
        numberOffset: CGSize
    ) -> some View {
        ZStack {
            Circle()
                .stroke(AppColor.accent, lineWidth: Metric.strokeWidth * scale)
                .frame(width: diameter, height: diameter)
                .offset(circleOffset)

            Text(number)
                .font(.system(size: 24 * scale, weight: .heavy, design: .rounded))
                .foregroundColor(AppColor.accent)
                .offset(numberOffset)
        }
    }
}

#Preview {
    WrongGearCountIllustration()
        .previewBackdrop(.cameraFeed)
}
