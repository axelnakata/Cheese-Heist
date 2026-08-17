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

import Foundation
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
    @ObservationIgnored private weak var level2: Level2ViewModel?
    @ObservationIgnored private(set) var cutsceneCoordinator: CutsceneSceneCoordinator?
    @ObservationIgnored private var hasBooted = false
    @ObservationIgnored private var level1TickerID: UUID?
    @ObservationIgnored private var level2TickerID: UUID?

    /// Chooses the first route. Runs once per process.
    ///
    /// `RootView` calls this from `onAppear`, which is not a once-only hook — it fires
    /// again whenever the view it is attached to is re-established. That was harmless
    /// while boot's destination WAS the app's only screen; now that splash hands off to
    /// the cutscene, which hands off to the blueprint, which hands off to Level 1, an
    /// unguarded re-entry throws the child straight back to the splash screen the
    /// moment they arrive anywhere downstream.
    func boot() {
        guard !hasBooted else { return }
        hasBooted = true

        guard ARCapabilityChecker.isLiDARAvailable else {
            router.navigate(to: .unsupportedDevice)
            return
        }
        router.navigate(to: .splash)
    }

    // MARK: - Cutscene

    /// Starts the session and stands up the cutscene's scene coordinator.
    ///
    /// ═══ `setupARView()`, NOT `arSessionManager.arView`. ═══
    ///
    /// `startSession()` bails out silently when the view does not exist yet, and the
    /// view is created by `ARViewContainer.makeUIView` — which is not guaranteed to have
    /// run by the time the enclosing `ZStack`'s `onAppear` fires. Reading the optional
    /// meant that on a cold launch the coordinator was never built and the ViewModel was
    /// never attached, so the scan overlay sat on `.noSurface` forever: a permanent red
    /// ✗ over a perfectly good table, and no ring, whatever the child pointed at.
    ///
    /// Level 1 never hit this because it defers its scene to detection-lock, by which
    /// point the view has certainly been made. `setupARView()` is memoised, so calling
    /// it here returns the same instance the container will use.
    func startCutscene(with viewModel: CutsceneViewModel) {
        guard cutsceneCoordinator == nil else { return }

        let arView = arSessionManager.setupARView()
        arSessionManager.startSession()
        ticker.start(in: arView)

        let scene = CutsceneSceneCoordinator(arView: arView, ticker: ticker)
        scene.onValidityChanged = { [weak viewModel] validity in
            viewModel?.refreshSurfaceValidity(validity)
        }
        cutsceneCoordinator = scene
        viewModel.attach(scene: scene)

        viewModel.onHandoff = { [weak self] in
            self?.cutsceneCoordinator = nil
            self?.router.navigate(to: .blueprint)
        }
    }

    /// Tears down any existing AR 3D scene, resets vision detection, and clears active level references
    /// so the next level calibration starts fresh from scratch.
    func resetARGameplay() {
        coordinator?.teardown()
        coordinator = nil
        detection.reset()
        level1 = nil
        level2 = nil
    }

    // MARK: - Level 1

    /// Starts the session and the detector for a Level 1 attempt, and stands up the
    /// scene the moment a pair locks.
    func startLevel1(with viewModel: Level1ViewModel) {
        resetARGameplay()
        level1 = viewModel
        viewModel.onTeardownRequested = { [weak self] in self?.restartAttempt() }

        arSessionManager.startSession()
        detection.onTrackingUpdate = { [weak self] frame, gears in
            self?.trackingUpdate(frame: frame, gears: gears)
        }
        detection.start(source: arSessionManager)
        startLevel1Ticker()
    }

    // MARK: - Level 2

    /// Starts the session and the detector for a Level 2 attempt.
    /// Same wiring as Level 1 but uses Level 2 tuning and scene director.
    func startLevel2(with viewModel: Level2ViewModel) {
        resetARGameplay()
        level2 = viewModel
        viewModel.onTeardownRequested = { [weak self] in self?.restartAttempt() }

        arSessionManager.startSession()
        detection.onTrackingUpdate = { [weak self] frame, gears in
            self?.trackingUpdateLevel2(frame: frame, gears: gears)
        }
        detection.start(source: arSessionManager)
        startLevel2Ticker()
    }

    // MARK: - The two clocks (Level 1)

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

    /// RENDER CLOCK, 60 Hz, in the PRD-Level1 §6.1 order.
    private func startLevel1Ticker() {
        guard level1TickerID == nil else { return }

        let arView = arSessionManager.setupARView()
        ticker.start(in: arView)

        level1TickerID = ticker.register { [weak self] deltaTime in
            guard let self else { return }
            coordinator?.smoothAlignment(deltaTime: deltaTime)
            level1?.advance(deltaTime: Double(deltaTime))
            coordinator?.refreshProjection(session: arSessionManager.session)
        }
    }

    // MARK: - The two clocks (Level 2)

    /// FAST PATH for Level 2 — identical structure, different scene director.
    private func trackingUpdateLevel2(frame: CraneFrame, gears: [DetectedGear]) {
        guard let level2, let arView = arSessionManager.arView else { return }

        if coordinator == nil {
            let ordered = GearOrdering.leftToRight(gears, in: frame)
            guard let assignment = Level2SceneDirector.initialAssignment(leftToRight: ordered)
            else { return }
            let scene = GameplaySceneCoordinator()
            scene.build(
                frame: frame, gears: gears, assignment: assignment,
                liftHeight: Float(Level2Tuning.value.liftHeight), in: arView
            )
            // The one line that makes Level 2's scene different from Level 1's. The cat
            // is opted into here rather than branched on inside the coordinator — see
            // `GameplaySceneCoordinator+CatPatrol`.
            scene.startCatPatrol()
            coordinator = scene
            level2.attach(scene: scene)
            return
        }

        coordinator?.correctAlignment(toward: frame, session: arSessionManager.session)
    }

    /// RENDER CLOCK for Level 2.
    private func startLevel2Ticker() {
        guard level2TickerID == nil else { return }

        let arView = arSessionManager.setupARView()
        ticker.start(in: arView)

        level2TickerID = ticker.register { [weak self] deltaTime in
            guard let self else { return }
            coordinator?.smoothAlignment(deltaTime: deltaTime)
            // After alignment, so the cat's circle is laid out in an already-corrected
            // frame; before physics, because it shares nothing with it.
            coordinator?.advanceCatPatrol(deltaTime: deltaTime)
            level2?.advance(deltaTime: Double(deltaTime))
            coordinator?.refreshProjection(session: arSessionManager.session)
        }
    }

    /// Retry. The scene goes and the detector starts looking again; the session does
    /// not move. A fresh coordinator is built on the next lock, which is how one
    /// attempt per coordinator and one `session.run` per process coexist.
    private func restartAttempt() {
        coordinator?.teardown()
        coordinator = nil
        detection.reset()
        detection.start(source: arSessionManager)
    }
}
