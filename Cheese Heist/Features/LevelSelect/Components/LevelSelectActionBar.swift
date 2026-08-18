//
//  LevelSelectActionBar.swift
//  Cheese Heist
//
//  Figma 1031:188 (rewatch cutscene) + 1031:185 (Play), bottom-right corner.
//

import SwiftUI

struct LevelSelectActionBar: View {

    let onPlay: () -> Void
    let onWatchCutscene: () -> Void

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let sideInset: CGFloat = 68
        static let bottomInset: CGFloat = 76
        static let spacing: CGFloat = 16
    }

    var body: some View {
        HStack(spacing: Metric.spacing * scale) {
            LargeCTAButton(icon: .cutscene, action: onWatchCutscene)
            PrimaryButton(title: "Play", action: onPlay)
        }
        .padding(.trailing, Metric.sideInset * scale)
        .padding(.bottom, Metric.bottomInset * scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
}

#Preview {
    LevelSelectActionBar(onPlay: {}, onWatchCutscene: {})
        .previewBackdrop(.parchment)
}
