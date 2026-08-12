//
//  LiftRunner.swift
//  Cheese Heist
//
//  The physics loop. Advances `GearTrainSimulator` once per render frame and tells the
//  scene where everything now is.
//
//  IT KNOWS NOTHING ABOUT PHASES. It is handed a `LiftSegment` — a single `Double` —
//  and idles when handed nil. The guided run and the free run are the identical code
//  path, differing only in that number, which is what stops a `if guided` branch
//  appearing in `Core/`.
//

import Foundation

@MainActor
final class LiftRunner {

    private(set) var state = GearTrainState()

    /// The ceiling this run is allowed to reach, or nil to idle.
    var segment: LiftSegment?

    /// Fired once, on the frame the cheese first touches the ceiling.
    var onReachedCeiling: (() -> Void)?

    private let tuning: LevelTuning
    private weak var scene: (any CraneSceneProviding)?
    private var pair: GearPair?
    private var hasReportedCeiling = false

    /// How far this crane's cheese has to travel, in metres.
    ///
    /// ═══ MEASURED AT THE START OF EACH SEGMENT, NOT TUNED AND NOT PER FRAME. ═══
    ///
    /// It was `tuning.liftHeight`, a flat 6cm, while the drop to the table is whatever
    /// the child built — so on a taller crane the run "reached the ceiling" with the
    /// cheese still swinging halfway up its rope, and the level declared it secured.
    ///
    /// Latched rather than read live because the table estimate keeps improving while
    /// the child cranks, and a ceiling that moves under a lift in progress is a lift
    /// that speeds up and slows down for no reason the child can see.
    private var liftHeight: Double

    init(tuning: LevelTuning, scene: (any CraneSceneProviding)?) {
        self.tuning = tuning
        self.scene = scene
        self.liftHeight = tuning.liftHeight
    }

    /// The two gears this run uses, read ONCE from the assignment.
    ///
    /// Detection never reaches physics: an improving pose estimate must never alter a
    /// run already in progress, so the tooth counts are copied in here rather than
    /// looked up per frame.
    func setPair(_ pair: GearPair) {
        self.pair = pair
    }

    var isCranking: Bool {
        get { state.isCranking }
        set { state.isCranking = newValue }
    }

    /// 0…1 against the FULL lift height, not against this segment's ceiling — so the
    /// guided run's progress bar stops at 0.5 rather than filling twice.
    var progress: Double {
        guard liftHeight > 0 else { return 0 }
        return min(1, state.height / liftHeight)
    }

    /// The tuning the simulator actually runs on: this crane's travel, everything else
    /// as authored.
    private var measuredTuning: LevelTuning {
        tuning.lifting(to: liftHeight)
    }

    /// One render frame.
    func advance(deltaTime: Double) {
        guard let segment, let pair else { return }

        let outcome = GearTrainSimulator.advance(
            state: &state, pair: pair, tuning: measuredTuning,
            segment: segment, deltaTime: deltaTime
        )

        scene?.apply(state: state, ratio: pair.ratio)

        guard outcome == .reachedCeiling, !hasReportedCeiling else { return }
        hasReportedCeiling = true
        onReachedCeiling?()
    }

    /// Opens the ceiling for the next segment without moving the cheese — this is what
    /// the mid-lift teaching beat resumes into.
    func continueInto(_ next: LiftSegment) {
        measureTravel()
        segment = next
        hasReportedCeiling = false
    }

    /// Asks the scene how far the cheese has to go. Ignores a scene that has not
    /// measured its table yet rather than latching a zero.
    private func measureTravel() {
        guard let measured = scene.map({ Double($0.maximumLift) }), measured > 0 else { return }
        liftHeight = measured
    }

    /// Drops the cheese back to the table and zeroes the gears.
    ///
    /// Fires on entry to `selectingRoles`, NOT `freeCrank`: the cheese comes down while
    /// the child is still choosing roles, so the free run starts from zero and they can
    /// see it has been re-armed.
    func reset() {
        GearTrainSimulator.reset(state: &state)
        measureTravel()
        hasReportedCeiling = false
        segment = nil
        if let pair { scene?.apply(state: state, ratio: pair.ratio) }
    }
}
