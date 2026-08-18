//
//  GearDetectionService.swift
//  Cheese Heist
//
//  Drives `GearDetector` over live AR frames, decides when the result is trustworthy
//  enough to act on, and then keeps it true for the rest of the session. One job —
//  turn a stream of frames into a continuously correct "these two gears, at these world
//  positions, seen from here" answer.
//
//  Nothing here freezes the camera. The session runs continuously and this only reads
//  the frames it publishes.
//
//  WHY IT KEEPS RUNNING AFTER THE LOCK (parent PRD §12.2 says to stop; amended):
//  The lock settles WHICH gears these are. It does not settle where they are forever —
//  that answer is only ever as good as the viewpoints it was measured from, and the
//  child is about to supply better ones by walking around. So detection does not stop
//  at the lock, and it does not stop after a fixed refinement budget either: whatever
//  number you pick, the child's most interesting movement is as likely to fall after it
//  as before it, and once it expires the overlay is frozen against a stale estimate
//  with no way back.
//
//  This file holds state and lifecycle; the per-frame loop is in `+Loop`.
//

import ARKit
import Foundation
import Observation
import QuartzCore
import os

@MainActor
@Observable
final class GearDetectionService {

    /// How often the model runs.
    ///
    /// This is not the floor on how stale the overlay can be — the ARKit anchor carries
    /// the scene at 60 Hz and detection only nudges it, over about a second. So the rate
    /// buys no responsiveness, and 6 Hz buys back a chunk of sustained CPU, which
    /// matters more than it sounds: the thermal throttling that inference provokes
    /// degrades ARKit's own tracking, the thing now doing the real work.
    static let detectionsPerSecond: Double = 6

    /// The app simulates exactly one driver/follower pair.
    static let requiredGearCount = 2

    /// How long the gears can be out of frame before the HUD says so. Debounced so a
    /// single stray frame (a hand passing over the crane, a quick tilt) doesn't flip the
    /// crane-lost fallback on.
    static let trackingLostAfter: TimeInterval = 4.0

    /// How long the wrong gear count must persist during setup before the fallback
    /// screen shows. Debounced for the same reason — one frame that miscounts (motion
    /// blur, a hand mid-build) must not fire the fallback on its own.
    static let gearCountIssueDebounceAfter: TimeInterval = 4.0

    // MARK: - Observable state (slow path, ~2 Hz)

    internal(set) var phase: GearDetectionPhase = .idle
    internal(set) var gears: [DetectedGear] = []
    internal(set) var craneFrame: CraneFrame?
    internal(set) var lockProgress: Double = 0
    internal(set) var isTracking = false
    internal(set) var hasLostGears = false
    internal(set) var liveGearCountIssue: GearCountIssue?

    /// Bumped every time `craneFrame` and `gears` are republished. Views watch this
    /// rather than the frame itself, which is float noise and would fire constantly.
    internal(set) var trackingVersion = 0

    /// True once the model has seen a gear steadily enough that the alignment
    /// illustration has done its job.
    ///
    /// STORED, NOT COMPUTED OFF `viability`. The gate itself is `@ObservationIgnored`,
    /// so a computed mirror of it changed without ever notifying anyone: `Level1View`
    /// only re-reads the detector when `phase` or `trackingVersion` changes, and during
    /// the search neither does — `phase` sits on `.searching` and `trackingVersion` is
    /// not bumped until the lock. The illustration therefore stayed up forever. This is
    /// the one flag whose whole job is to be noticed, so it is a real property.
    internal(set) var isViable = false

    /// The pair as the CHILD sees them, left to right. Empty or single until a frame
    /// has been solved.
    var gearsLeftToRight: [DetectedGear] {
        guard let craneFrame else { return gears }
        return GearOrdering.leftToRight(gears, in: craneFrame)
    }

    /// Fast path (~6 Hz) — see `GearTrackingPublisher`. Bypasses Observation on
    /// purpose: the alignment filter wants every measurement it can get.
    @ObservationIgnored
    var onTrackingUpdate: ((CraneFrame, [DetectedGear]) -> Void)? {
        get { publisher.onTrackingUpdate }
        set { publisher.onTrackingUpdate = newValue }
    }

    // MARK: - Collaborators

    @ObservationIgnored let estimator = CranePlaneEstimator()
    @ObservationIgnored let publisher = GearTrackingPublisher()
    /// Var, not let: Level 1 disables this (`.disabled`) since it has no manual-fallback
    /// screen to hand off to and relies entirely on the live setup/crane-lost overlays.
    /// Level 2 leaves it at `.standard` — see `AppServices.startLevel1`/`startLevel2`.
    @ObservationIgnored var timeout = DetectionTimeoutPolicy.standard
    @ObservationIgnored var vote = GearPairVote()
    @ObservationIgnored var viability = DetectionViabilityGate()

    @ObservationIgnored var detector: GearDetector?
    @ObservationIgnored weak var source: ARSessionManager?
    @ObservationIgnored var isDetecting = false
    @ObservationIgnored var searchStartedAt: TimeInterval = 0
    @ObservationIgnored var lastTrackedAt: TimeInterval = 0
    @ObservationIgnored var lastSeenCount = 0
    @ObservationIgnored var wrongCountCandidate: GearCountIssue?
    @ObservationIgnored var firstWrongCountSeenAt: TimeInterval = 0

    @ObservationIgnored private var timer: Timer?

    init() {}

    // MARK: - Lifecycle

    func start(source: ARSessionManager) {
        guard !phase.isLocked else { return }

        if detector == nil {
            do {
                detector = try GearDetector()
            } catch {
                let reason = error.localizedDescription
                phase = .unavailable(.modelUnavailable(reason))
                Logger.detection.error("\(reason, privacy: .public)")
                return
            }
        }

        self.source = source
        clearEstimates()
        searchStartedAt = CACurrentMediaTime()
        phase = .searching

        let poll = Timer(timeInterval: 1 / Self.detectionsPerSecond, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(poll, forMode: .common)
        timer = poll
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        source = nil
        isTracking = false
        hasLostGears = false
        clearWrongGearCount()
        if phase == .searching { phase = .idle }
    }

    /// Full reset, for retry. The ARSession is untouched — see PRD-Level1 §6.1.
    func reset() {
        stop()
        clearEstimates()
        phase = .idle
    }

    /// Clears the current mismatch issue and restarts the debounce window when the user taps "I fixed it!".
    func recheckGearCountIssue() {
        clearWrongGearCount()
    }

    func clearWrongGearCount() {
        wrongCountCandidate = nil
        firstWrongCountSeenAt = 0
        liveGearCountIssue = nil
    }

    private func clearEstimates() {
        vote.reset()
        viability.reset()
        estimator.reset()
        publisher.reset()
        clearWrongGearCount()
        gears = []
        craneFrame = nil
        lockProgress = 0
        isTracking = false
        hasLostGears = false
        isViable = false
        trackingVersion = 0
        lastSeenCount = 0
    }
}
