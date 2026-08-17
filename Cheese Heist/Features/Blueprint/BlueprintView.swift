//
//  BlueprintView.swift
//  Cheese Heist
//
//  PRD §11.4 — the 3-step build guide. Ported from the reference build
//  (`cheezy-dev-nay`'s `LegoTutorialView`): the blueprint artwork positions its own
//  step number, media, instructions and nav buttons proportionally via `GeometryReader`,
//  matching what that build was actually tuned against, rather than a re-derivation
//  from the Figma frame's absolute coordinates. Nav buttons reuse this project's
//  existing `LargeCTAButton` in place of the reference build's own circular button.
//

import SwiftUI

struct BlueprintView: View {

    /// Set by `RootView` to `router.navigate(to: .level1)`.
    let onFinished: () -> Void

    @State private var viewModel = BlueprintViewModel()

    var body: some View {
        ZStack {
            Image("bg_kitchen")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text(viewModel.currentStep.title)
                    .font(.custom("ChalkboardSE-Bold", size: 50))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
                    .offset(x: 50)
                    .padding(.top, 100)

                sheet
                Spacer()
            }

            if viewModel.showsCheckIn {
                BlueprintCheckInBubble(text: viewModel.currentStep.checkInLine)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: viewModel.showsCheckIn)
        .statusBarHidden()
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    private var sheet: some View {
        ZStack {
            Image("blueprint_bg")
                .resizable()
                .scaledToFit()
                .frame(width: 1148)
                .offset(x: 5, y: -80)

            GeometryReader(content: sheetContent)
        }
        .frame(maxWidth: 900)
        .padding(.horizontal, 40)
    }

    private func sheetContent(_ geo: GeometryProxy) -> some View {
        let width = geo.size.width
        let height = geo.size.height

        return ZStack {
            Text(viewModel.currentStep.stepLabel)
                .font(.custom("ChalkboardSE-Bold", size: 55))
                .foregroundColor(.white)
                .position(x: width * 0.94, y: height * 0.12)

            BlueprintGIFView(gifName: viewModel.currentStep.gifName)
                .frame(width: 700)
                .position(x: width * 0.35, y: height * 0.5)

            BlueprintInstructionList(instructions: viewModel.currentStep.instructions)
                .frame(width: width * 0.35, alignment: .leading)
                .position(x: width * 0.78, y: height * 0.5)

            if !viewModel.isFirstStep {
                LargeCTAButton(icon: .back, action: goBack)
                    .position(x: width * 0.01, y: height * 0.91)
            }

            LargeCTAButton(icon: .next, action: goNext)
                .position(x: width * 1.01, y: height * 0.91)
        }
    }

    private func goBack() {
        withAnimation(.easeInOut) { viewModel.goBack() }
    }

    private func goNext() {
        withAnimation(.easeInOut) {
            if viewModel.goNext() { onFinished() }
        }
    }
}

#Preview {
    BlueprintView(onFinished: {})
}
