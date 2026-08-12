//
//  Level1HandOverLayer.swift
//  Cheese Heist
//
//  "It's your turn!" — the beat between the guided run and the child's own.
//
//  It is a full-width tap target on purpose. This is the one moment the child is being
//  handed control, and making them find a small button to accept it is exactly the
//  wrong shape for a six-year-old.
//

import SwiftUI

struct Level1HandOverLayer: View {

    let onContinue: () -> Void

    /// False while a speech bubble is up, because the bubble prints the same words
    /// directly under itself. Two "tap to continue"s on one screen — one under the
    /// bubble and one along the bottom — read as two different things to tap.
    var showsHint: Bool = true

    @Environment(\.layoutScale) private var scale

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: onContinue)

            if showsHint {
                VStack {
                    Spacer()
                    TapToContinueHint(title: "tap to continue..")
                        .padding(.bottom, AppSpacing.xxl * scale)
                }
            }
        }
    }
}

#Preview("With the hint") {
    Level1HandOverLayer(onContinue: {})
        .previewBackdrop(.cameraFeed)
}

#Preview("Tap target only — a bubble is up") {
    Level1HandOverLayer(onContinue: {}, showsHint: false)
        .previewBackdrop(.cameraFeed)
}
