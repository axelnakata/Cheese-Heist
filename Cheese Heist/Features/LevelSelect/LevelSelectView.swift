//
//  LevelSelectView.swift
//  Cheese Heist
//
//  Figma "Little Einstein Board" 431:92 — the level-select frame, wired in
//  `RootView` between `.blueprint` and `.level1`. `onPlay` and `onWatchCutscene` are
//  handed in rather than owned here, same as `BlueprintView.onFinished` — this view
//  describes the screen, `RootView` decides where its buttons lead. Which level
//  "Play" starts, and a future "Select Level" entry from the result screen, are both
//  routing decisions still to be made; this view only needs the current selection to
//  exist, not to be reachable from anywhere else yet.
//

import SwiftUI

struct LevelSelectView: View {

    let onPlay: () -> Void
    let onWatchCutscene: () -> Void

    @State private var viewModel = LevelSelectViewModel()

    var body: some View {
        ZStack {
            LevelSelectBackground()

            VStack {
                Spacer()
                LevelPathView(stops: viewModel.stops)
                Spacer()
            }

            LevelSelectActionBar(onPlay: onPlay, onWatchCutscene: onWatchCutscene)
        }
        .statusBarHidden()
    }
}

#Preview {
    LevelSelectView(onPlay: {}, onWatchCutscene: {})
}
