//
//  Level1View.swift
//  Cheese Heist
//
//  The Level 1 screen: the live camera, the overlay layers over it, and the success
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
    @State private var dismissedGearCountIssue = false

    init(services: AppServices) {
        self.services = services
        _viewModel = State(initialValue: Level1ViewModel(detection: services.detection))
    }

    var body: some View {
        ZStack {
            ARViewContainer(arSessionManager: services.arSessionManager)
                .ignoresSafeArea()

            overlays

            if viewModel.showsResult {
                SuccessOverlay(
                    title: Level1Script.successTitle,
                    subtitle: Level1Script.successSubtitle,
                    earnedStars: viewModel.earnedStars,
                    onRetry: { withAnimation { viewModel.handle(.tappedRetry) } },
                    onHome: { services.router.navigate(to: .levelSelect) },
                    onNext: { services.router.navigate(to: .level2) }
                )
                .transition(.opacity)
            }
        }
        .statusBarHidden()
        .animation(.easeInOut(duration: AppDuration.transition), value: viewModel.phase)
        .onAppear {
            services.startLevel1(with: viewModel)
            viewModel.playMainAudio()
        }
        .onChange(of: services.detection.trackingVersion) { _, _ in
            viewModel.observeDetection()
        }
        .onChange(of: services.detection.phase) { _, _ in
            viewModel.observeDetection()
        }
        // The third signal, and the one that takes the illustration down. Neither of the
        // other two moves during the search — `phase` sits on `.searching` and
        // `trackingVersion` is not bumped until the lock — so without this the child
        // frames the crane perfectly and nothing happens.
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

    /// Pre-lock only, and mutually exclusive with the alignment illustration — see
    /// `showsAlignmentIllustration`'s doc comment.
    private var showsWrongGearCount: Bool {
        (viewModel.phase == .aligningCrane || viewModel.phase == .detectingGears)
            && services.detection.liveGearCountIssue != nil
            && !dismissedGearCountIssue
    }

    /// Nothing is interactive while the crane is lost mid-game — the joystick comes off
    /// screen along with everything else, not just visually behind the scrim.
    private var effectiveGate: Level1InputGate {
        services.detection.hasLostGears ? .none : viewModel.inputGate
    }

    @ViewBuilder
    private var overlays: some View {
        if Level1PhasePresentation.showsAlignmentIllustration(viewModel.phase) && !showsWrongGearCount {
            CraneAlignmentLayer(title: Level1Script.alignment)
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
                isEnabled: effectiveGate.gearsTappable,
                onTap: { viewModel.tapGear($0) }
            )

            Level1HUDLayer(
                chip: viewModel.chipText,
                targets: viewModel.screenTargets,
                gate: effectiveGate,
                showsRoleLabels: viewModel.showsRoleLabels,
                hint: viewModel.crankHint,
                hasElevation: viewModel.hasElevation,
                onDrag: { point, centre in viewModel.crank.drag(to: point, centre: centre) },
                onRelease: { viewModel.crank.release() }
            )

            Level1TutorialLayer(
                showsJoystickHint: viewModel.showsJoystickHint,
                beat: viewModel.dialogue.current,
                isRevealComplete: viewModel.dialogue.isRevealComplete,
                mouseAnchor: viewModel.mouseAnchor,
                onRevealComplete: { viewModel.dialogue.markRevealComplete() }
            )
        }
    }
}
