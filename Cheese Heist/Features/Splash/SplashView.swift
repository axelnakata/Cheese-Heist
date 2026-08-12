//
//  SplashView.swift
//  Cheese Heist
//
//  PRD §11.1 — Figma `splash screen` (526:58). Ported directly from the reference build
//  (`cheezy-dev-nay`): layout, offsets, gear rotation and the ChalkboardSE-Bold tap
//  label are all taken verbatim from there rather than re-derived, since that build is
//  the one actually verified against the design. Only asset names (already renamed into
//  this catalogue) and the tap handler (a closure instead of a local `fullScreenCover`)
//  differ.
//

import SwiftUI

struct SplashView: View {

    /// Set by `RootView` to `router.navigate(to: .cutscene)`.
    let onTapToPlay: () -> Void

    @State private var viewModel = SplashViewModel()

    var body: some View {
        ZStack {
            Image("bg_kitchen")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                Spacer()
                logoGroup
                Spacer()
                tapToPlayButton
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap()
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .onAppear { viewModel.startAnimations() }
    }

    private var logoGroup: some View {
        ZStack {
            gearsOverlay

            Image("mouse_hole")
                .resizable()
                .scaledToFit()
                .frame(width: 420)
                .offset(x: 170, y: 255)

            Image(viewModel.model.logoAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 680)
                .offset(x: 50, y: 80)

            Image("splash_mouse")
                .resizable()
                .scaledToFit()
                .frame(width: 222)
                .offset(x: 205, y: 257)
        }
        .allowsHitTesting(false)
    }

    private var gearsOverlay: some View {
        ZStack {
            Image("gear_small")
                .resizable()
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(viewModel.isGearRotating ? -360 : 0))
                .animation(
                    viewModel.isGearRotating
                        ? .linear(duration: 2).repeatForever(autoreverses: false)
                        : .default,
                    value: viewModel.isGearRotating
                )
                .offset(x: -70, y: -140)

            Image("gear_big")
                .resizable()
                .frame(width: 330, height: 330)
                .rotationEffect(.degrees(viewModel.isGearRotating ? 360 : 0))
                .animation(
                    viewModel.isGearRotating
                        ? .linear(duration: 8).repeatForever(autoreverses: false)
                        : .default,
                    value: viewModel.isGearRotating
                )
                .offset(x: -220, y: -80)
        }
    }

    private var tapToPlayButton: some View {
        Button(action: handleTap) {
            Text(viewModel.model.tapToPlayText)
                .font(.custom("ChalkboardSE-Bold", size: 52))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 2)
                .contentShape(Rectangle())
        }
        .zIndex(1)
        .padding(.bottom, 125)
    }

    private func handleTap() {
        guard viewModel.tapToPlay() else { return }
        onTapToPlay()
    }
}

#Preview {
    SplashView(onTapToPlay: {})
}
