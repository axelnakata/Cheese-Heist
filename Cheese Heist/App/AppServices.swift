//
//  AppServices.swift
//  Cheese Heist
//
//  The composition root.
//
//  `ARSessionManager` is created here, at launch, ABOVE `AppRouter` — so the session
//  outlives every route change and `session.run` is called exactly once per process
//  (PRD-Level1 §6.1). A manager owned by a screen would be torn down and re-run on
//  every navigation, and every re-run silently invalidates every world anchor.
//
//  This is also where the two-clock wiring is made: the detector's 6 Hz fast path goes
//  straight into the coordinator's alignment filter, and the scene ticker fans out the
//  render loop in the fixed §6.1 order.
//

import Observation

@MainActor
@Observable
final class AppServices {

    let arSessionManager = ARSessionManager()
    let detection = GearDetectionService()
    let router = AppRouter()

    @ObservationIgnored let ticker = SceneUpdateTicker()
    @ObservationIgnored private(set) var coordinator: GameplaySceneCoordinator?
    @ObservationIgnored private weak var level1: Level1ViewModel?

    func boot() {
        guard ARCapabilityChecker.isLiDARAvailable else {
            router.navigate(to: .unsupportedDevice)
            return
        }
        router.navigate(to: .level1)
    }

    /// Starts the session and the detector for a Level 1 attempt, and stands up the
    /// scene the moment a pair locks.
    func startLevel1(with viewModel: Level1ViewModel) {
        level1 = viewModel
        viewModel.onTeardownRequested = { [weak self] in self?.restartAttempt() }

        arSessionManager.startSession()
        detection.onTrackingUpdate = { [weak self] frame, gears in
            self?.trackingUpdate(frame: frame, gears: gears)
        }
        detection.start(source: arSessionManager)
        startTicker()
    }

    // MARK: - The two clocks

    /// FAST PATH, ~6 Hz. Builds the scene on the first locked solution, then does
    /// nothing but hand later measurements to the alignment filter.
    private func trackingUpdate(frame: CraneFrame, gears: [DetectedGear]) {
        guard let level1, let arView = arSessionManager.arView else { return }

        if coordinator == nil {
            let ordered = GearOrdering.leftToRight(gears, in: frame)
            guard let assignment = Level1SceneDirector.initialAssignment(leftToRight: ordered)
            else { return }
            let scene = GameplaySceneCoordinator()
            scene.build(
                frame: frame, gears: gears, assignment: assignment,
                liftHeight: Float(Level1Tuning.value.liftHeight), in: arView
            )
            coordinator = scene
            level1.attach(scene: scene)
            return
        }

        coordinator?.correctAlignment(toward: frame, session: arSessionManager.session)
    }

    /// RENDER CLOCK, 60 Hz, in the PRD-Level1 §6.1 order: alignment first so physics
    /// writes into an already-corrected frame, projection last so the SwiftUI overlay
    /// reads the same frame it draws.
    private func startTicker() {
        guard let arView = arSessionManager.arView else { return }

        ticker.register { [weak self] deltaTime in
            guard let self else { return }
            coordinator?.smoothAlignment(deltaTime: deltaTime)
            level1?.advance(deltaTime: Double(deltaTime))
            coordinator?.refreshProjection(session: arSessionManager.session)
        }
        ticker.start(in: arView)
    }

    /// Retry. The scene goes and the detector starts looking again; the session does
    /// not move. A fresh coordinator is built on the next lock, which is how one
    /// attempt per coordinator and one `session.run` per process coexist.
    private func restartAttempt() {
        coordinator?.teardown()
        coordinator = nil
        detection.start(source: arSessionManager)
    }
}
