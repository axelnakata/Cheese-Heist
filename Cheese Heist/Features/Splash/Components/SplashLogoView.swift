//
//  SplashLogoView.swift
//  Cheese Heist
//
//  The wordmark group: two meshed gears, a mouse peeking from its hole, and the
//  "Cheese Heist" logo. Composition and offsets carried over from the reference build —
//  the gears turn opposite ways because they are drawn meshed (small gear fast and
//  counter-clockwise, big gear slow and clockwise), matching LO-2 rather than
//  contradicting it just because this pair is decorative, not the lesson's own gears.
//

import SwiftUI

struct SplashLogoView: View {

    let logoAssetName: String

    @Environment(\.layoutScale) private var scale
    @State private var bigGearRotation: Angle = .zero
    @State private var smallGearRotation: Angle = .zero

    /// Figma `splash screen` (526:58), read off the reference composition.
    private enum Metric {
        static let logoWidth: CGFloat = 680
        static let mouseHoleWidth: CGFloat = 420
        static let mouseWidth: CGFloat = 222
        static let bigGearWidth: CGFloat = 330
        static let smallGearWidth: CGFloat = 220
        static let bigGearRevolution: Double = 8
        static let smallGearRevolution: Double = 2
        static let bigGearOffset = CGSize(width: -220, height: -80)
        static let smallGearOffset = CGSize(width: -70, height: -140)
        static let mouseHoleOffset = CGSize(width: 170, height: 255)
        static let mouseOffset = CGSize(width: 205, height: 257)
        static let logoOffset = CGSize(width: 50, height: 80)
    }

    var body: some View {
        ZStack {
            gear(
                "gear_big", width: Metric.bigGearWidth,
                rotation: bigGearRotation, offset: Metric.bigGearOffset
            )
            gear(
                "gear_small", width: Metric.smallGearWidth,
                rotation: smallGearRotation, offset: Metric.smallGearOffset
            )
            layer("mouse_hole", width: Metric.mouseHoleWidth, offset: Metric.mouseHoleOffset)
            layer(logoAssetName, width: Metric.logoWidth, offset: Metric.logoOffset)
            layer("splash_mouse", width: Metric.mouseWidth, offset: Metric.mouseOffset)
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cheese Heist")
        .onAppear(perform: startGearRotation)
    }

    private func layer(_ name: String, width: CGFloat, offset: CGSize) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: width * scale)
            .offset(x: offset.width * scale, y: offset.height * scale)
    }

    private func gear(_ name: String, width: CGFloat, rotation: Angle, offset: CGSize) -> some View {
        layer(name, width: width, offset: offset)
            .rotationEffect(rotation)
    }

    private func startGearRotation() {
        withAnimation(.linear(duration: Metric.bigGearRevolution).repeatForever(autoreverses: false)) {
            bigGearRotation = .degrees(360)
        }
        withAnimation(.linear(duration: Metric.smallGearRevolution).repeatForever(autoreverses: false)) {
            smallGearRotation = .degrees(-360)
        }
    }
}

#Preview {
    SplashLogoView(logoAssetName: SplashModel.level1.logoAssetName)
        .previewBackdrop(.cameraFeed)
}
