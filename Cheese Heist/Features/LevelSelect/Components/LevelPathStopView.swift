//
//  LevelPathStopView.swift
//  Cheese Heist
//
//  One stop on the level path. Figma 1025:426 (numbered marker), 1025:466 (mouse's
//  current position, with its light-effect glow) and 1021:376 / 1025:467 / 1031:113 /
//  1025:491 (locked levels — same disc, different fill, plus a padlock) all reduce to
//  the same footprint, so a single view switches on `kind` rather than four call sites.
//

import SwiftUI

struct LevelPathStopView: View {

    // Figma's platform art has no drop shadow — the 3D render's own shading carries it.
    static let defaultShadowOpacity: Double = 0

    let kind: LevelSelectStop.Kind
    let platformShadowOpacity: Double

    init(kind: LevelSelectStop.Kind, platformShadowOpacity: Double = defaultShadowOpacity) {
        self.kind = kind
        self.platformShadowOpacity = platformShadowOpacity
    }

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let platformWidth: CGFloat = 169
        static let numberSize: CGFloat = 56
        static let numberShadowRadius: CGFloat = 3.5
        static let mouseWidth: CGFloat = 164
        static let mouseYOffset: CGFloat = -78
        static let glowWidth: CGFloat = 480
        static let wedgeYOffset: CGFloat = 58
    }

    var body: some View {
        ZStack {
            switch kind {
            case .marker(let number):
                platform("level_select_unlocked_platform")
                Text("\(number)")
                    .appText(AppFont.largeTitle)
                    .foregroundStyle(AppColor.textOnAccent)
                    .shadow(
                        color: AppColor.accentPressed,
                        radius: 0,
                        x: Metric.numberShadowRadius * scale,
                        y: Metric.numberShadowRadius * scale
                    )
                    .offset(y: -Metric.wedgeYOffset * 0.25 * scale)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                CheeseWedgeCluster()
                    .offset(y: Metric.wedgeYOffset * scale)
                    .allowsHitTesting(false)

            case .current:
                Image("level_select_glow")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Metric.glowWidth * scale)
                    .offset(y: -220 * scale)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                platform("level_select_unlocked_platform")
                Image("level_select_mouse")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Metric.mouseWidth * scale)
                    .offset(y: Metric.mouseYOffset * scale)
                    .allowsHitTesting(false)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                CheeseWedgeCluster()
                    .offset(y: Metric.wedgeYOffset * scale)
                    .allowsHitTesting(false)

            case .locked:
                platform("level_select_locked_platform")
            }
        }
    }

    private func platform(_ imageName: String) -> some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: Metric.platformWidth * scale)
            .shadow(color: .black.opacity(platformShadowOpacity), radius: 14 * scale, x: 0, y: 6 * scale)
    }
}

#Preview {
    HStack(spacing: 40) {
        LevelPathStopView(kind: .marker(number: 1))
        LevelPathStopView(kind: .current)
        LevelPathStopView(kind: .locked)
    }
    .previewBackdrop(.parchment)
}
