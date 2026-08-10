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

    @Environment(\.layoutScale) private var scale

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: onContinue)

            VStack {
                Spacer()
                TapToContinueHint()
                    .padding(.bottom, AppSpacing.xxl * scale)
            }
        }
    }
}

#Preview {
    Level1HandOverLayer(onContinue: {})
        .previewBackdrop(.cameraFeed)
}
