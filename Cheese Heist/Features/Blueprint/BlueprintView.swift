//
//  BlueprintView.swift
//  Cheese Heist
//
//  PRD §11.4 — the 3-step build guide. Full-screen, non-AR. `LargeCTAButton(.next)`
//  bottom-right on every step; `.back` bottom-left on steps 2 and 3.
//

import SwiftUI

struct BlueprintView: View {

    /// Set by `RootView` to `router.navigate(to: .level1)`.
    let onFinished: () -> Void

    @State private var viewModel = BlueprintViewModel()
    @Environment(\.layoutScale) private var scale

    var body: some View {
        ZStack {
            background

            VStack(spacing: AppSpacing.l * scale) {
                Text(viewModel.currentStep.title)
                    .appText(AppFont.largeTitle)
                    .foregroundStyle(AppColor.textOnCamera)
                    .frame(width: BlueprintSheetView.width * scale, alignment: .leading)

                BlueprintSheetView(step: viewModel.currentStep)
                Spacer()
            }
            .padding(.top, AppSpacing.xxl * scale)

            navigationButtons
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .animation(.easeInOut(duration: AppDuration.transition), value: viewModel.stepIndex)
    }

    private var background: some View {
        ZStack {
            Image("bg_kitchen").resizable().scaledToFill()
            AppColor.surfaceScrim
        }
        .ignoresSafeArea()
    }

    private var navigationButtons: some View {
        VStack {
            Spacer()
            HStack {
                if !viewModel.isFirstStep {
                    LargeCTAButton(icon: .back, action: viewModel.goBack)
                }
                Spacer()
                LargeCTAButton(icon: .next, action: handleNext)
            }
            .padding(.horizontal, AppSpacing.xl * scale)
            .padding(.bottom, AppSpacing.xl * scale)
        }
    }

    private func handleNext() {
        if viewModel.goNext() { onFinished() }
    }
}

#Preview {
    BlueprintView(onFinished: {})
}
