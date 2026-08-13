//
//  Level2View.swift
//  Cheese Heist
//
//  The Level 2 screen: the live camera, overlay layers over it, and the result overlay
//  on top.
//
//  Same architectural rules as Level1View:
//  - RESULT IS AN OVERLAY, NOT A ROUTE.
//  - This view composes and never decides.
//  - Every "should this be visible" question is answered by `Level2InputGate` or
//    `Level2PhasePresentation`.
//

import SwiftUI

struct Level2View: View {

    let services: AppServices

    @State private var viewModel: Level2ViewModel

    init(services: AppServices) {
        self.services = services
        _viewModel = State(initialValue: Level2ViewModel(detection: services.detection))
    }

    var body: some View {
        ZStack {
            ARViewContainer(arSessionManager: services.arSessionManager)
                .ignoresSafeArea()

            overlays

            if viewModel.isResult {
                resultOverlay
                    .transition(.opacity)
            }
        }
        .statusBarHidden()
        .animation(.easeInOut(duration: AppDuration.transition), value: viewModel.phase)
        .onAppear { services.startLevel2(with: viewModel) }
        .onChange(of: services.detection.trackingVersion) { _, _ in
            viewModel.observeDetection()
        }
        .onChange(of: services.detection.phase) { _, _ in
            viewModel.observeDetection()
        }
        .onChange(of: services.detection.isViable) { _, _ in
            viewModel.observeDetection()
        }
    }

    @ViewBuilder
    private var overlays: some View {
        if Level2PhasePresentation.showsAlignmentIllustration(viewModel.phase) {
            CraneAlignmentLayer(title: Level2Script.alignment)
        }

        GearSelectionTapLayer(
            targets: viewModel.screenTargets,
            isEnabled: viewModel.inputGate.gearsTappable,
            onTap: { viewModel.tapGear($0) }
        )

        Level2HUDLayer(
            chip: viewModel.chipText,
            targets: viewModel.screenTargets,
            showsRoleLabels: viewModel.showsRoleLabels,
            showsTimer: viewModel.showsTimer,
            timerSeconds: viewModel.timerRemaining,
            showsCheeseCountdown: viewModel.showsCheeseCountdown,
            solidCheeseCount: viewModel.starCount,
            showsRestart: viewModel.inputGate.restartVisible,
            onRestart: { withAnimation { viewModel.tapRestart() } }
        )

        Level2PlayingLayer(
            showsBars: viewModel.showsBars,
            strengthLevel: viewModel.strengthLevel,
            speedLevel: viewModel.speedLevel,
            joystickEnabled: viewModel.inputGate.joystickEnabled,
            engagement: viewModel.crank.engagement,
            onDrag: { point, centre in viewModel.crank.drag(to: point, centre: centre) },
            onRelease: { viewModel.crank.release() }
        )

        if viewModel.phase == .manualFallback, let failure = services.detection.phase.failure {
            DetectionManualFallbackSheet(
                failure: failure,
                onChoose: { viewModel.chooseManualPair($0, $1) },
                onRetry: { services.detection.start(source: services.arSessionManager) }
            )
        }
    }

    private var resultOverlay: some View {
        let copy = viewModel.resultCopy
        return SuccessOverlay(
            title: copy.title,
            subtitle: copy.subtitle,
            onRetry: { withAnimation { viewModel.handle(.tappedRetry) } },
            onNext: viewModel.isFail ? nil : { viewModel.handle(.tappedNext) },
            starCount: viewModel.resultStarCount,
            timeRemaining: viewModel.isFail ? nil : viewModel.timerRemaining,
            mouseAssetName: viewModel.resultMouseSprite,
            showNext: !viewModel.isFail
        )
    }
}
