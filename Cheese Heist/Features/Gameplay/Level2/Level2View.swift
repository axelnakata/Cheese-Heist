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
    @State private var dismissedGearCountIssue = false

    init(services: AppServices) {
        self.services = services
        _viewModel = State(initialValue: Level2ViewModel(detection: services.detection))
    }

    var body: some View {
        ZStack {
            ARViewContainer(arSessionManager: services.arSessionManager)
                .ignoresSafeArea()

            overlays

            if viewModel.showsResult {
                resultOverlay
                    .transition(.opacity)
            }
        }
        .statusBarHidden()
        .animation(.easeInOut(duration: AppDuration.transition), value: viewModel.phase)
        .onAppear {
            services.startLevel2(with: viewModel)
            viewModel.playMainAudio()
        }
        .onChange(of: services.detection.trackingVersion) { _, _ in
            viewModel.observeDetection()
        }
        .onChange(of: services.detection.phase) { _, _ in
            viewModel.observeDetection()
        }
        .onChange(of: services.detection.isViable) { _, _ in
            viewModel.observeDetection()
        }
        .onChange(of: services.detection.liveGearCountIssue) { old, new in
            if old == nil && new != nil {
                dismissedGearCountIssue = false
            }
        }
        .onChange(of: services.detection.hasLostGears) { _, _ in
            viewModel.observeDetection()
        }
    }

    /// Pre-lock only, mirroring `Level1View.showsWrongGearCount`.
    private var showsWrongGearCount: Bool {
        (viewModel.phase == .aligningCrane || viewModel.phase == .detectingGears)
            && services.detection.liveGearCountIssue != nil
            && !dismissedGearCountIssue
    }

    @ViewBuilder
    private var overlays: some View {
        if Level2PhasePresentation.showsAlignmentIllustration(viewModel.phase) && !showsWrongGearCount {
            CraneAlignmentLayer(title: Level2Script.alignment)
        }

        if showsWrongGearCount, let issue = services.detection.liveGearCountIssue {
            WrongGearCountLayer(
                issue: issue,
                onFixed: {
                    dismissedGearCountIssue = true
                    services.detection.recheckGearCountIssue()
                }
            )
        }

        if services.detection.hasLostGears && !viewModel.showsResult {
            CraneLostLayer()
        } else {
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
                isTimerRunning: viewModel.isTimerRunning,
                showsCheeseCountdown: viewModel.showsCheeseCountdown,
                solidCheeseCount: viewModel.starCount,
                showsRestart: viewModel.inputGate.restartVisible,
                onRestart: { withAnimation { viewModel.tapRestart() } }
            )

            Level2PlayingLayer(
                showsBars: viewModel.showsBars,
                strengthLevel: viewModel.strengthLevel,
                speedLevel: viewModel.speedLevel,
                showsJoystick: viewModel.showsJoystick,
                joystickEnabled: viewModel.inputGate.joystickEnabled,
                hint: viewModel.crankHint,
                hasElevation: viewModel.hasElevation,
                onDrag: { point, centre in viewModel.crank.drag(to: point, centre: centre) },
                onRelease: { viewModel.crank.release() }
            )
        }
    }

    private var resultOverlay: some View {
        let copy = viewModel.resultCopy
        return SuccessOverlay(
            title: copy.title,
            subtitle: copy.subtitle,
            onRetry: { withAnimation { viewModel.handle(.tappedRetry) } },
            onHome: { services.router.navigate(to: .levelSelect) },
            starCount: viewModel.resultStarCount,
            timeRemaining: viewModel.isFail ? nil : viewModel.timerRemaining,
            mouseAssetName: viewModel.resultMouseSprite,
            showNext: false
        )
    }
}
