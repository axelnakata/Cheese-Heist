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

    private(set) var phase: Level1Phase = .aligningCrane
    private(set) var inputGate = Level1InputGate.of(.aligningCrane)

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

    func handle(_ event: Level1Event) {
        applyPayload(of: event)
        guard let next = Level1PhaseMachine.next(from: phase, on: event) else { return }
        phase = next
        inputGate = Level1InputGate.of(next)
        Level1PhaseCommands.apply(next, in: context)
    }

    private var context: Level1PhaseContext {
        Level1PhaseContext(
            director: director, runner: runner, selection: selection,
            dialogue: dialogue, crank: crank, detection: detection,
            onTeardown: { [weak self] in self?.tearDownScene() }
        )
    }

    /// The part of an event that is data rather than a transition. Runs BEFORE the
    /// machine, so the entry effects see the assignment the event carried.
    private func applyPayload(of event: Level1Event) {
        switch event {
        case .detectionLocked(let pair, let assignment),
             .manualPairChosen(let pair, let assignment):
            selection.begin(assignment: assignment)
            runner?.setPair(pair)
            scene?.apply(assignment: assignment, animated: false)

        case .tappedGear(let id):
            guard let next = selection.assignDriver(id) else { return }
            scene?.apply(assignment: next, animated: true)
            // The free run's physics follows the child's choice: swapping the roles
            // swaps the ratio, which is the whole point of letting them choose.
            if let pair = pairFor(next) { runner?.setPair(pair) }

        case .tappedPull:
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

        let runner = LiftRunner(tuning: tuning, scene: scene)
        runner.onReachedCeiling = { [weak self] in self?.handle(.liftReachedCeiling) }
        self.runner = runner
    }

    private func tearDownScene() {
        scene?.teardown()
        scene = nil
        director = nil
        runner = nil
        dialogue.reset()
    }

    private func pairFor(_ assignment: GearRoleAssignment) -> GearPair? {
        Level1SceneDirector.pair(for: detection.gears, assignment: assignment)
    }

    // MARK: - Input

    /// A tap anywhere the current phase treats as "next".
    func tapToContinue() {
        guard inputGate.tapAdvances else { return }
        guard dialogue.beats.isEmpty || dialogue.advance() else { return }
        handle(.tappedContinue)
    }

    func tapGear(_ id: UUID) {
        guard inputGate.gearsTappable else { return }
        handle(.tappedGear(id: id))
    }

    func tapPull() {
        guard inputGate.pullVisible else { return }
        handle(.tappedPull)
    }

    /// One render frame, fanned out by `SceneUpdateTicker`.
    func advance(deltaTime: Double) {
        runner?.isCranking = inputGate.joystickEnabled && crank.isCranking
        runner?.advance(deltaTime: deltaTime)
    }

    // MARK: - Presentation

    var screenTargets: [GearScreenTarget] { scene?.screenTargets ?? [] }
    var mouseAnchor: CGPoint? { scene?.mouseScreenAnchor }
    var chipText: String? { Level1PhasePresentation.chip(for: phase) }
    var spotlight: SpotlightSubject { director?.spotlight(for: phase) ?? .none }
    var isSucceeded: Bool { phase == .succeeded }
    var liftProgress: Double { runner?.progress ?? 0 }

    /// Whether a speech bubble is on screen right now. The bubble prints its own
    /// tap-to-continue hint, so the full-screen one stands down while it is up.
    var hasDialogue: Bool { dialogue.current != nil }
}
