//
//  Level1ViewModel.swift
//  Cheese Heist
//
//  ═══ THIS TYPE NEVER IMPORTS ARKit, RealityKit, Vision OR simd. ═══
//
//  Every value crossing into it is a `CGPoint`, a `Double`, a `UUID` or a type from
//  `Features/…/Models`. `GearScreenProjector` does the world-to-screen conversion so
//  this only ever handles points, and `CraneSceneProviding` is the whole of its view
//  onto the scene — which is also what lets a preview stand a mock in its place.
//
//  It holds one `Level1Phase` and delegates everything else to seven collaborators,
//  which is how it stays inside the 160-line ViewModel cap on a flow this long.
//

import Foundation
import Observation

@MainActor
@Observable
final class Level1ViewModel {

    var earnedStars: Int = 3

    private(set) var phase: Level1Phase = .aligningCrane
    private(set) var inputGate = Level1InputGate.of(.aligningCrane)
    private(set) var hasElevation = false

    private let resultReveal = ResultRevealController()
    var showsResult: Bool { resultReveal.showsResult }

    let detection: GearDetectionService
    let dialogue = DialogueSequencer()
    let selection = GearSelectionViewModel()
    let crank = CrankInputViewModel()

    @ObservationIgnored private(set) var runner: LiftRunner?
    @ObservationIgnored private(set) var director: Level1SceneDirector?
    @ObservationIgnored private var scene: (any CraneSceneProviding)?
    @ObservationIgnored private let tuning: LevelTuning
    @ObservationIgnored var onTeardownRequested: (() -> Void)?

    init(detection: GearDetectionService, tuning: LevelTuning = Level1Tuning.value) {
        self.detection = detection
        self.tuning = tuning
    }

    // MARK: - The whole machine

    /// ═══ AN EVENT THE MACHINE REJECTS HAS NO EFFECTS EITHER. ═══
    ///
    /// The payload used to be applied BEFORE the machine was consulted, so an event the
    /// current phase ignores still rewrote the state it carried. `observeDetection()`
    /// republishes `.detectionLocked` on every tracking update — several times a second,
    /// for the whole level — and each one re-seeded the roles from
    /// `initialAssignment`. The child tapped the 40T, the mouse started walking to it,
    /// and a fifth of a second later the driver was the left gear again. That is the
    /// whole of "I can't choose which gear is the driver".
    func handle(_ event: Level1Event) {
        guard let next = Level1PhaseMachine.next(from: phase, on: event) else { return }
        applyPayload(of: event)
        phase = next
        inputGate = Level1InputGate.of(next)
        Level1PhaseCommands.apply(next, in: context)

        if next == .succeeded {
            resultReveal.reveal(after: .success)
        } else {
            resultReveal.hide()
        }
    }

    private var context: Level1PhaseContext {
        Level1PhaseContext(
            director: director, runner: runner, selection: selection,
            dialogue: dialogue, crank: crank, detection: detection, starCount: earnedStars,
            onTeardown: { [weak self] in self?.tearDownScene() }
        )
    }

    /// The part of an event that is data rather than a transition. Runs after the
    /// machine has ACCEPTED the event and before the entry effects, so those see the
    /// assignment the event carried.
    private func applyPayload(of event: Level1Event) {
        switch event {
        case .detectionLocked(let pair, let assignment):
            selection.begin(assignment: assignment)
            runner?.setPair(pair)
            scene?.apply(assignment: assignment, animated: false)

        case .tappedGear(let id):
            guard let next = selection.assignDriver(id) else { return }
            scene?.apply(assignment: next, animated: true)
            // The free run's physics follows the child's choice: swapping the roles
            // swaps the ratio, which is the whole point of letting them choose.
            if let pair = pairFor(next) { runner?.setPair(pair) }

        case .joystickEngaged:
            selection.commit()

        default:
            break
        }
    }

    // MARK: - Scene attachment

    /// Called once the coordinator has built the scene on the detection lock.
    func attach(scene: any CraneSceneProviding) {
        self.scene = scene
        director = Level1SceneDirector(scene: scene)

        let runner = LiftRunner(
            tuning: tuning, scene: scene,
            durationProvider: { Level1LiftDurations.duration(for: $0) }
        )
        runner.onReachedCeiling = { [weak self] in self?.handle(.liftReachedCeiling) }
        self.runner = runner
    }

    /// Retry. Drops this attempt's scene and then asks the host to start the next one.
    ///
    /// ═══ THE SECOND HALF IS NOT OPTIONAL. ═══
    ///
    /// `onTeardownRequested` was wired up in `AppServices` and never called, and the
    /// symptom was the whole of "retry goes back to the calibration screen and then just
    /// sits there". Two things were left undone by dropping the handles here. The
    /// detector had already been reset by `Level1PhaseCommands` and nobody ever started
    /// it looking again, so no lock could arrive; and `AppServices` still held the torn
    /// down coordinator, so even a lock that did arrive took the "already built" branch
    /// and corrected the alignment of a scene with no entities left in it.
    private func tearDownScene() {
        scene?.teardown()
        scene = nil
        director = nil
        runner = nil
        dialogue.reset()
        hasElevation = false
        onTeardownRequested?()
    }

    private func pairFor(_ assignment: GearRoleAssignment) -> GearPair? {
        Level1SceneDirector.pair(for: detection.gears, assignment: assignment)
    }

    // MARK: - Input

    func tapGear(_ id: UUID) {
        guard inputGate.gearsTappable else { return }
        handle(.tappedGear(id: id))
    }

    /// One render frame, fanned out by `SceneUpdateTicker`.
    ///
    /// The crank is refreshed here rather than only on a gesture callback: a finger held
    /// still on the ring sends nothing, and "nothing" has to mean disengaged rather than
    /// "whatever it was last time".
    ///
    /// The first turn is what locks the assignment in and starts the free run — mirrors
    /// `Level2ViewModel.advance`.
    func advance(deltaTime: Double) {
        crank.refresh()

        if phase == .rolesChosen && inputGate.joystickEnabled && crank.isCranking {
            handle(.joystickEngaged)
        }

        runner?.drive = inputGate.joystickEnabled ? crank.drive : .holding
        runner?.advance(deltaTime: deltaTime)

        let elevated = (runner?.state.height ?? 0) > 0.0001
        if elevated != hasElevation {
            hasElevation = elevated
        }
    }

    // MARK: - Presentation

    var screenTargets: [GearScreenTarget] { scene?.screenTargets ?? [] }
    var mouseAnchor: CGPoint? { scene?.mouseScreenAnchor }
    var chipText: String? { Level1PhasePresentation.chip(for: phase) }
    var showsRoleLabels: Bool { Level1PhasePresentation.showsRoleLabels(phase) }
    var showsJoystickHint: Bool { Level1PhasePresentation.showsJoystickHint(phase) }
    var isSucceeded: Bool { phase == .succeeded }
    var liftProgress: Double { runner?.progress ?? 0 }
    var crankHint: CrankHint {
        .of(drive: crank.drive, isPressed: crank.isPressed, hasElevation: hasElevation)
    }

    func playMainAudio() {
        AudioManager.shared.playBGM(.page1)
    }
}
