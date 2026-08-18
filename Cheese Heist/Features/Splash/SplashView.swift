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

    /// Developer navigation shortcuts.
    var onDevLevel1: (() -> Void)?
    var onDevLevel2: (() -> Void)?

    @State private var viewModel = SplashViewModel()
    
    @State private var isComplete = false
    @State private var canContinue = false

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
                
                tapToPlayTypewriter
            }

            VStack {
                HStack {
                    Spacer()
                    devShortcutsOverlay
                }
                Spacer()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap()
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .onAppear {
            viewModel.startAnimations()
            viewModel.playSplashAudio()
        }
    }

    // MARK: - View Components

    private var tapToPlayTypewriter: some View {
        Group {
            TypewriterText(
                text: AttributedString(viewModel.model.tapToPlayText),
                charactersPerSecond: 30,
                isComplete: $isComplete,
                canContinue: $canContinue
            )
            .font(.custom("ChalkboardSE-Bold", size: 52))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 2)
            .opacity(canContinue ? 1.0 : 0.7)
        }
        .padding(.bottom, 125)
        .zIndex(1)
    }

    private var devShortcutsOverlay: some View {
        HStack(spacing: AppSpacing.s) {
            Button("Level 1") { onDevLevel1?() }
                .appText(AppFont.subtitle)
                .foregroundStyle(AppColor.textOnCamera)
                .padding(.horizontal, AppSpacing.s)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColor.surfaceInstruction)
                .clipShape(Capsule())

            Button("Level 2") { onDevLevel2?() }
                .appText(AppFont.subtitle)
                .foregroundStyle(AppColor.textOnCamera)
                .padding(.horizontal, AppSpacing.s)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColor.surfaceInstruction)
                .clipShape(Capsule())
        }
        .padding(.top, AppSpacing.l)
        .padding(.trailing, AppSpacing.l)
        .zIndex(10)
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
                .frame(width: 245)
                .offset(x: 170, y: 255)
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

    // MARK: - Logic Integrasi (Gabungan Code 1 & Code 2)

    private func handleTap() {
        if !isComplete {
            isComplete = true
            return
        }

        guard canContinue else { return }

        AudioManager.shared.playSFX(.tap1)
        guard viewModel.tapToPlay() else { return }
        onTapToPlay()
    }
}

#Preview {
    SplashView(onTapToPlay: {})
}
