//
//  GearDetectionService+Loop.swift
//  Cheese Heist
//
//  The per-frame half of the detector: one tick, the vote, the lock, and the timeout.
//

import ARKit
import Foundation
import QuartzCore
import os

extension GearDetectionService {

    // MARK: - One tick

    func tick() {
        guard phase == .searching || isTracking, !isDetecting,
              let detector, let frame = source?.currentFrame else { return }

        if phase == .searching,
           timeout.hasTimedOut(elapsed: CACurrentMediaTime() - searchStartedAt) {
            failTimeout()
            return
        }

        isDetecting = true
        defer { isDetecting = false }

        let detections: [GearDetection]
        do {
            detections = try detector.detect(in: frame.capturedImage)
        } catch {
            Logger.detection.debug("inference failed: \(error.localizedDescription, privacy: .public)")
            return
        }

        lastSeenCount = detections.count
        if viability.observe(gearCount: detections.count) { isViable = true }

        guard detections.count == Self.requiredGearCount else {
            // Any frame that doesn't show exactly two gears breaks the streak — a lock
            // should mean "two gears, steadily", not "two gears, eventually". While
            // tracking there is no streak to break and nothing to correct: the scene is
            // already placed, the crane has not moved, and the child has looked away.
            guard !isTracking else { return noteTrackingGap() }
            vote.reset()
            lockProgress = 0
            noteWrongGearCount(count: detections.count)
            return
        }

        clearWrongGearCount()

        guard let captured = source?.captureData(from: frame) else { return }
        solve(detections: detections, captured: captured)
    }

    private func solve(detections: [GearDetection], captured: CapturedFrameData) {
        let solution = estimator.track(detections: detections, captured: captured)

        guard !isTracking else {
            // A rejected solve is NOT a lost crane. The estimator declines frames it
            // cannot measure from, and holding the pose is the correct answer there —
            // the anchor is already carrying it. Warning the child would be telling them
            // something is wrong while the overlay sits exactly where it should.
            guard let solution else { return }
            hasLostGears = false
            lastTrackedAt = CACurrentMediaTime()
            publish(solution, detections: detections, force: false)
            return
        }

        advanceSearch(solution: solution, detections: detections)
    }

    // MARK: - Searching

    /// Vote on the tooth counts, and lock once they and a usable geometric solution
    /// both arrive.
    private func advanceSearch(solution: CranePlaneSolution?, detections: [GearDetection]) {
        guard let first = GearType(rawValue: detections[0].toothCount),
              let second = GearType(rawValue: detections[1].toothCount) else { return }

        let settled = vote.submit((first, second))

        // Two things have to arrive, so progress shows the slower of them rather than
        // racing ahead on whichever finishes first.
        let probes = Double(estimator.sampleCount)
        let needed = Double(CranePlaneOffsetTracker.samplesForDegradedLock)
        lockProgress = min(vote.progress, min(1, probes / needed))

        // A USABLE answer, not a settled one. Everything that makes an answer wrong
        // rather than imprecise is already rejected inside `track`, which returns nil
        // rather than a bad solution. What is left is only imprecision, and tracking
        // settles that. Requiring a usable solve is strictly stronger than the parent
        // PRD §12.3 confidence floor it replaces.
        guard settled != nil, let solution else { return }
        lock(solution: solution, detections: detections)
    }

    // MARK: - Locking

    private func lock(solution: CranePlaneSolution, detections: [GearDetection]) {
        publish(solution, detections: detections, force: true)
        phase = .locked
        lockProgress = 1
        clearWrongGearCount()

        // The timer stays alive and changes job. Everything after this is free
        // improvement, paid for by movement the child was going to do anyway.
        isTracking = true
        hasLostGears = false
        lastTrackedAt = CACurrentMediaTime()

        let elapsed = CACurrentMediaTime() - searchStartedAt
        let summary = gears.map { "\($0.toothCount)T" }.joined(separator: " + ")
        Logger.detection.info(
            "locked \(summary, privacy: .public) in \(elapsed, format: .fixed(precision: 1))s"
        )
    }

    private func publish(
        _ solution: CranePlaneSolution, detections: [GearDetection], force: Bool
    ) {
        guard let updated = publisher.publish(
            solution: solution, detections: detections, previous: gears, force: force
        ) else { return }

        gears = updated
        craneFrame = solution.frame
        trackingVersion += 1
    }

    /// Records an off-count frame during setup. Debounced ~1s so a single stray frame
    /// doesn't flip the fallback screen on.
    func noteWrongGearCount(count: Int, now: TimeInterval = CACurrentMediaTime()) {
        let issue: GearCountIssue = count < Self.requiredGearCount ? .tooFew : .tooMany(count)
        if wrongCountCandidate != issue {
            wrongCountCandidate = issue
            firstWrongCountSeenAt = now
        } else if now - firstWrongCountSeenAt >= Self.gearCountIssueDebounceAfter {
            liveGearCountIssue = issue
        }
    }

    /// The gears were not usable this frame. Nothing moves; after a moment the HUD is
    /// told, so the child knows why the overlay has stopped keeping up.
    func noteTrackingGap(now: TimeInterval = CACurrentMediaTime()) {
        guard !hasLostGears,
              now - lastTrackedAt > Self.trackingLostAfter else { return }
        hasLostGears = true
    }

    // MARK: - Timeout

    /// Reached the time limit. Not necessarily a failure — if the estimator has
    /// collected enough to work with, locking on a slightly under-baked estimate beats
    /// making the child start over, and tracking will sharpen it from there.
    private func failTimeout() {
        if let degraded = degradedSolution() {
            Logger.detection.info("timed out but locking on a degraded estimate")
            lock(solution: degraded.solution, detections: degraded.detections)
            return
        }

        phase = .timedOut(failureForLastFrame())
        lockProgress = 0
        stop()
    }

    private func degradedSolution() -> (solution: CranePlaneSolution, detections: [GearDetection])? {
        guard vote.consensus != nil, estimator.canProduceDegradedResult,
              let detector, let frame = source?.currentFrame,
              let captured = source?.captureData(from: frame),
              let detections = try? detector.detect(in: frame.capturedImage),
              detections.count == Self.requiredGearCount,
              let solution = estimator.track(detections: detections, captured: captured)
        else { return nil }
        return (solution, detections)
    }

    private func failureForLastFrame() -> GearDetectionFailure {
        switch lastSeenCount {
        case 0: return .noGears
        case 1: return .tooFew
        // Saw the gears the whole time and never fixed the plane.
        case Self.requiredGearCount: return .noDepth
        default: return .tooMany(lastSeenCount)
        }
    }
}
