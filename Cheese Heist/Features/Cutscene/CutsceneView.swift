//
//  CutsceneView.swift
//  Cheese Heist
//
//  The cutscene screen: live camera, surface scan overlay, narrating mouse, and the
//  blueprint handoff. Mirrors `Level1View`'s composition — the view composes and never
//  decides. Every "is this tappable" question is answered by `CutsceneInputGate`.
//
//  Layout reference: `Docs/cutscene frames/`.
//

import SwiftUI

struct CutsceneView: View {

    let services: AppServices

    @State private var viewModel = CutsceneViewModel()
    @Environment(\.layoutScale) private var scale

    var body: some View {
        ZStack {
            ARViewContainer(arSessionManager: services.arSessionManager)
                .ignoresSafeArea()

            overlays
        }
        .statusBarHidden()
        .animation(.easeInOut(duration: AppDuration.transition), value: viewModel.phase)
        .onAppear { services.startCutscene(with: viewModel) }
    }

    @ViewBuilder
    private var overlays: some View {
        switch viewModel.phase {
        case .scanning:
            SurfaceScanLayer(
                validity: viewModel.surfaceValidity,
                isTappable: viewModel.inputGate.surfaceTappable,
                onTap: viewModel.tapSurface
            )

        case .introducing:
            tapCatcher
            hint

        case .narrating:
            // Order matters: the scrim and blueprint go DOWN first, then the tap
            // catcher, then the mouse on top — in `cutscene 6.png` the mouse and its
            // bubble are the only things not dimmed, and the scrim swallowing taps is
            // what makes the blueprint the sole way out of the last beat.
            if viewModel.showsBlueprint {
                CutsceneBlueprintLayer(onTap: viewModel.tapBlueprint)
            }
            if viewModel.inputGate.tapAdvances { tapCatcher }
            CutsceneMouseLayer(
                beat: viewModel.currentBeat,
                dialogueBeat: viewModel.dialogue.current,
                isRevealComplete: viewModel.dialogue.isRevealComplete,
                onRevealComplete: viewModel.dialogue.markRevealComplete
            )

        case .handingOff:
            EmptyView()
        }
    }

    /// Full-screen tap target. Sits UNDER the mouse layer in the ZStack so the bubble
    /// keeps its own hit testing off and the whole screen advances the beat.
    private var tapCatcher: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { viewModel.tapToContinue() }
    }

    /// Only shown when there is no bubble — the bubble prints its own hint.
    @ViewBuilder
    private var hint: some View {
        if !viewModel.hasDialogue {
            VStack {
                Spacer()
                TapToContinueHint(title: "tap to continue..")
                    .padding(.bottom, AppSpacing.xxl * scale)
            }
            .allowsHitTesting(false)
        }
    }
}
