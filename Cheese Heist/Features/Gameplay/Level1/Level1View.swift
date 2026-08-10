//
//  Level1View.swift
//  Cheese Heist
//
//  The Level 1 screen: the live camera, four overlay layers over it, and the success
//  overlay on top.
//
//  SUCCESS IS AN OVERLAY, NOT A ROUTE (parent PRD §10 lists it as a screen). Routing
//  away would tear down the AR view and with it the frozen scene the child just built —
//  and the success frame draws the crane still standing behind the scrim, which is the
//  whole reward.
//
//  This view composes and never decides. Every "should this be visible" question is
//  answered by `Level1InputGate` or `Level1PhasePresentation`, so the phase switch
//  lives in one place rather than in each layer.
//

import SwiftUI

struct Level1View: View {

    let services: AppServices

    @State private var viewModel: Level1ViewModel

    init(services: AppServices) {
        self.services = services
        _viewModel = State(initialValue: Level1ViewModel(detection: services.detection))
    }

    var body: some View {
        ZStack {
            ARViewContainer(arSessionManager: services.arSessionManager)
                .ignoresSafeArea()

            overlays

            if viewModel.isSucceeded {
                SuccessOverlay(
                    title: Level1Script.successTitle,
                    subtitle: Level1Script.successSubtitle,
                    onRetry: { withAnimation { viewModel.handle(.tappedRetry) } },
                    onNext: { viewModel.handle(.tappedNext) }
                )
                .transition(.opacity)
            }
        }
        .statusBarHidden()
        .animation(.easeInOut(duration: AppDuration.transition), value: viewModel.phase)
        .onAppear { services.startLevel1(with: viewModel) }
        .onChange(of: services.detection.trackingVersion) { _, _ in
            viewModel.observeDetection()
        }
        .onChange(of: services.detection.phase) { _, _ in
            viewModel.observeDetection()
        }
    }

    @ViewBuilder
    private var overlays: some View {
        if Level1PhasePresentation.showsAlignmentIllustration(viewModel.phase) {
            CraneAlignmentLayer(title: Level1Script.alignment)
        }

        GearSelectionTapLayer(
            targets: viewModel.screenTargets,
            isEnabled: viewModel.inputGate.gearsTappable,
            onTap: { viewModel.tapGear($0) }
        )

        Level1HUDLayer(
            chip: viewModel.chipText,
            targets: viewModel.screenTargets,
            gate: viewModel.inputGate,
            showsRoleLabels: viewModel.inputGate.gearsTappable,
            onDrag: { point, centre in viewModel.crank.drag(to: point, centre: centre) },
            onRelease: { viewModel.crank.release() },
            onPull: { viewModel.tapPull() }
        )

        Level1TutorialLayer(
            subject: viewModel.spotlight,
            targets: viewModel.screenTargets,
            beat: viewModel.dialogue.current,
            isRevealComplete: viewModel.dialogue.isRevealComplete,
            onRevealComplete: { viewModel.dialogue.markRevealComplete() }
        )

        if viewModel.inputGate.tapAdvances {
            Level1HandOverLayer(onContinue: { viewModel.tapToContinue() })
        }

        if viewModel.phase == .manualFallback, let failure = services.detection.phase.failure {
            DetectionManualFallbackSheet(
                failure: failure,
                onChoose: { viewModel.chooseManualPair($0, $1) },
                onRetry: { services.detection.start(source: services.arSessionManager) }
            )
        }
    }
}
