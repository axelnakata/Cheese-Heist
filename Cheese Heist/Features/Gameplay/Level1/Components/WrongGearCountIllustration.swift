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
        static let width: CGFloat = 886
        static let height: CGFloat = 651
        static let craneWidth: CGFloat = 720
        static let badgeSize: CGFloat = 56
    }

    var body: some View {
        ZStack {
            craneBase

            gearMarker(
                number: "1",
                ellipseName: "Ellipse 47",
                offset: CGSize(width: -68 * scale, height: 18 * scale)
            )

            gearMarker(
                number: "2",
                ellipseName: "Ellipse 48",
                offset: CGSize(width: 44 * scale, height: 42 * scale)
            )
        }
        .frame(width: Metric.width * scale, height: Metric.height * scale)
        .accessibilityLabel("Crane illustration with two numbered gear positions")
    }

    @ViewBuilder
    private var craneBase: some View {
        if UIImage(named: "crane") != nil {
            Image("crane")
                .resizable()
                .scaledToFit()
                .frame(width: Metric.craneWidth * scale)
        } else {
            Image("crane_guidance")
                .resizable()
                .scaledToFit()
                .frame(width: Metric.width * scale, height: Metric.height * scale)
        }
    }

    @ViewBuilder
    private func gearMarker(number: String, ellipseName: String, offset: CGSize) -> some View {
        ZStack {
            if UIImage(named: ellipseName) != nil {
                Image(ellipseName)
                    .resizable()
                    .scaledToFit()
            }
            if UIImage(named: number) != nil {
                Image(number)
                    .resizable()
                    .scaledToFit()
            } else {
                Text(number)
                    .appText(AppFont.title)
                    .foregroundStyle(AppColor.textPrimary)
            }
        }
        .frame(width: Metric.badgeSize * scale, height: Metric.badgeSize * scale)
        .offset(offset)
    }
}

#Preview {
    WrongGearCountIllustration()
        .previewBackdrop(.cameraFeed)
}
