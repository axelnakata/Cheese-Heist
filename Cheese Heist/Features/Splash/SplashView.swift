//
//  SplashView.swift
//  Cheese Heist
//
//  PRD §11.1 — Figma `splash screen` (526:58). Full-bleed kitchen background, breathing
//  logo, pulsing tap hint. The whole screen is the tap target.
//

import SwiftUI

struct SplashView: View {

    /// Set by `RootView` to `router.navigate(to: .cutscene)` — this view never imports
    /// `AppRouter` itself, matching the rest of the app's screens.
    let onTapToPlay: () -> Void

    @State private var viewModel = SplashViewModel()
    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let tapToPlayBottomInset: CGFloat = 125
    }

    var body: some View {
        ZStack {
            background

            VStack {
                Spacer()
                SplashLogoView(logoAssetName: viewModel.model.logoAssetName)
                    .pulsing(period: 3, opacityRange: 1...1, scaleRange: 1...1.03)
                Spacer()
                tapToPlayLabel
                    .padding(.bottom, Metric.tapToPlayBottomInset * scale)
            }
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .contentShape(Rectangle())
        .onTapGesture(perform: handleTap)
    }

    private var background: some View {
        Image("bg_kitchen")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }

    private var tapToPlayLabel: some View {
        Text(viewModel.model.tapToPlayText)
            .appText(AppFont.largeTitle)
            .foregroundStyle(AppColor.textOnCamera)
            .pulsing(period: 1)
    }

    private func handleTap() {
        guard viewModel.tapToPlay() else { return }
        withAnimation(.easeInOut(duration: AppDuration.transition), onTapToPlay)
    }
}

#Preview {
    SplashView(onTapToPlay: {})
}
