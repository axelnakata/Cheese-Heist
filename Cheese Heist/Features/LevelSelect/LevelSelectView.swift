//
//  LevelSelectView.swift
//  Cheese Heist
//
//  Figma "Little Einstein Board" 431:92 — the level-select frame, wired in
//  `RootView` between `.blueprint` and `.level1`/`.level2`. Tapping an unlocked stop
//  moves the mouse to that stop, and "Play" navigates to the selected level.
//

import SwiftUI

struct LevelSelectView: View {

    let onPlay: (AppRoute) -> Void
    let onWatchCutscene: () -> Void
    var platformShadowOpacity: Double = LevelPathStopView.defaultShadowOpacity

    @State private var viewModel = LevelSelectViewModel()

    var body: some View {
        
        ZStack {
            LevelSelectBackground()

            VStack {
                Spacer()
                LevelPathView(
                    stops: viewModel.stops,
                    platformShadowOpacity: platformShadowOpacity,
                    onSelectStop: { stop in
                        withAnimation(.easeInOut(duration: AppDuration.transition)) {
                            _ = viewModel.selectStop(stop)
                        }
                    }
                )
                Spacer()
            }

            LevelSelectActionBar(
                onPlay: { onPlay(viewModel.selectedRoute) },
                onWatchCutscene: onWatchCutscene
            )
        }
        .statusBarHidden()
        .onAppear { viewModel.playMainAudio() }
    }
}

#Preview {
    LevelSelectView(onPlay: { _ in }, onWatchCutscene: {})
}
