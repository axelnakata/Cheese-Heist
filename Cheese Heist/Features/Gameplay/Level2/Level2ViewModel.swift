//
//  Level2ViewModel.swift
//  Cheese Heist
//
//  ═══ THIS TYPE NEVER IMPORTS ARKit, RealityKit, Vision OR simd. ═══
//
//  Same architectural rule as Level 1. The ViewModel holds one `Level2Phase`,
//  a countdown timer, the gear outcome, and delegates to the same collaborators.
//
//  What is new compared to Level 1:
//   • A 15-second countdown timer that starts when the joystick is first engaged.
//   • A stall-detection path that shakes for `Level2Tuning.stallShakeDuration` seconds,
//     then transitions to failedWeak.
//   • Gear-outcome evaluation (strength/speed bars, star scoring).
//   • No dialogue sequencer — Level 2 has no tutorial.
//

import Foundation
import Observation

@MainActor
@Observable
final class Level2ViewModel {

    private(set) var phase: Level2Phase = .aligningCrane
    private(set) var inputGate = Level2InputGate.of(.aligningCrane)

    let detection: GearDetectionService
    let selection = GearSelectionViewModel()
    let crank = CrankInputViewModel()

    // MARK: - Timer state

    /// The countdown timer, in seconds. Starts at 15, ticks down once cranking begins.
    private(set) var timerRemaining: Int = Level2Tuning.timerDuration
    private(set) var isTimerRunning = false
    private var timerAccumulator: Double = 0

    // MARK: - Outcome state

    private(set) var outcome: Level2GearOutcome?
    private(set) var starCount: Int = 3

    // MARK: - Stall shake

    private var shakeStartTime: Date?

    // MARK: - Private

    @ObservationIgnored private(set) var runner: LiftRunner?
    @ObservationIgnored private(set) var director: Level2SceneDirector?
    @ObservationIgnored private(set) var scene: (any CraneSceneProviding)?
    @ObservationIgnored private let tuning: LevelTuning
    @ObservationIgnored var onTeardownRequested: (() -> Void)?
    @ObservationIgnored private var currentPair: GearPair?

    init(detection: GearDetectionService, tuning: LevelTuning? = nil) {
        self.detection = detection
        self.tuning = tuning ?? Level2Tuning.value
    }

    // MARK: - The whole machine

    func handle(_ event: Level2Event) {
        guard let next = Level2PhaseMachine.next(from: phase, on: event) else { return }
        applyPayload(of: event)
        phase = next
        inputGate = Level2InputGate.of(next)
        Level2PhaseCommands.apply(next, in: context)
    }

    private var context: Level2PhaseContext {
        Level2PhaseContext(
            director: director, runner: runner, selection: selection,
            crank: crank, detection: detection,
            onTeardown: { [weak self] in self?.tearDownScene() }
        )
    }

    private func applyPayload(of event: Level2Event) {
        switch event {
        case .detectionLocked(let pair, let assignment):
            selection.begin(assignment: assignment)
            currentPair = pair
            runner?.setPair(pair)
            scene?.apply(assignment: assignment, animated: false)

        case .tappedGear(let id):
            guard let next = selection.assignDriver(id) else { return }
            scene?.apply(assignment: next, animated: true)
            if let pair = pairFor(next) {
                currentPair = pair
                runner?.setPair(pair)
            }

        case .joystickEngaged:
            // Lock the choice and evaluate the outcome
            selection.commit()
            evaluateOutcome()
            startTimer()

        case .tappedRestart:
            resetTimerState()

        case .tappedRetry:
            resetTimerState()

        default:
            break
        }
    }

    // MARK: - Scene attachment

    func attach(scene: any CraneSceneProviding) {
        self.scene = scene
        director = Level2SceneDirector(scene: scene)

        let runner = LiftRunner(
            tuning: tuning, scene: scene,
            durationProvider: { Level2GearOutcomeEvaluator.evaluate(pair: $0).estimatedLiftTime }
        )
        runner.onReachedCeiling = { [weak self] in self?.handle(.liftReachedCeiling) }
        self.runner = runner
    }

    private func tearDownScene() {
        scene?.teardown()
        scene = nil
        director = nil
        runner = nil
        resetTimerState()
        onTeardownRequested?()
    }

    private func pairFor(_ assignment: GearRoleAssignment) -> GearPair? {
        Level2SceneDirector.pair(for: detection.gears, assignment: assignment)
    }

    // MARK: - Outcome evaluation

    private func evaluateOutcome() {
        guard let pair = currentPair else { return }
        outcome = Level2GearOutcomeEvaluator.evaluate(pair: pair)

        // If the combination can't lift, immediately stall
        if outcome?.canLift == false {
            handle(.stallDetected)
        }
    }

    // MARK: - Timer

    private func startTimer() {
        guard !isTimerRunning else { return }
        isTimerRunning = true
        timerAccumulator = 0
        timerRemaining = Level2Tuning.timerDuration
    }

    private func resetTimerState() {
        isTimerRunning = false
        timerAccumulator = 0
        timerRemaining = Level2Tuning.timerDuration
        shakeStartTime = nil
        outcome = nil
        starCount = 3
    }

    /// Called every render frame during cranking.
    private func tickTimer(deltaTime: Double) {
        guard isTimerRunning, phase == .cranking else { return }
        timerAccumulator += deltaTime

        if timerAccumulator >= 1.0 {
            let seconds = Int(timerAccumulator)
            timerAccumulator -= Double(seconds)
            timerRemaining = max(0, timerRemaining - seconds)
        }

        // Update cheese count based on time remaining
        starCount = Level2GearOutcomeEvaluator.solidCheeseCount(timeRemaining: timerRemaining)

        // Check if timer expired
        if timerRemaining <= 0 {
            isTimerRunning = false
            handle(.timerExpired)
        }
    }

    /// Called every render frame. Drives the gear-clash shake visual whenever the phase
    /// is `.stallShaking` and clears it everywhere else, then checks whether
    /// `stallShakeDuration` has passed.
    private func tickShake(deltaTime: Double) {
        scene?.setGearStrain(phase == .stallShaking, deltaTime: deltaTime)
        guard phase == .stallShaking else { return }

        if shakeStartTime == nil {
            shakeStartTime = Date()
        }

        if let start = shakeStartTime,
            Date().timeIntervalSince(start) >= Level2Tuning.stallShakeDuration {
            handle(.shakeCompleted)
        }
    }

    // MARK: - Input

    func tapGear(_ id: UUID) {
        guard inputGate.gearsTappable else { return }
        handle(.tappedGear(id: id))
    }

    func tapRestart() {
        handle(.tappedRestart)
    }

    /// One render frame, fanned out by `SceneUpdateTicker`.
    func advance(deltaTime: Double) {
        crank.refresh()

        // Detect joystick engagement — the transition from not-cranking to cranking
        // while in rolesChosen phase triggers the joystickEngaged event.
        if phase == .rolesChosen && inputGate.joystickEnabled && crank.isCranking {
            handle(.joystickEngaged)
        }

        runner?.isCranking = inputGate.joystickEnabled && crank.isCranking
        runner?.advance(deltaTime: deltaTime)

        tickTimer(deltaTime: deltaTime)
        tickShake(deltaTime: deltaTime)
    }
}
