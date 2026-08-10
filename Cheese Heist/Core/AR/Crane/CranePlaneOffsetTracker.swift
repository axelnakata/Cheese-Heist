//
//  CranePlaneOffsetTracker.swift
//  Cheese Heist
//
//  Owns `trackedPlaneOffset` — how far the crane's plane sits along the tracked
//  normal, as the constant `c` in `{ x : dot(normal, x) = c }`.
//
//  THE ONLY POSITIONAL STATE THAT SURVIVES A FRAME. Everything else about where the
//  gears are is re-derived from the rays of the frame being drawn.
//

import simd

final class CranePlaneOffsetTracker {

    /// How much of a measured distance to take per frame.
    static let blend: Float = 0.25

    /// Probes needed before the estimator will produce anything at all.
    static let samplesForDegradedLock = 3

    /// Probes needed before the estimate can be called settled.
    static let samplesForStability = 6

    /// Recent distance measurements the agreement test looks at.
    static let agreementWindow = 10

    /// How closely those must agree before the estimate is called stable, in metres.
    static let stabilityTolerance: Float = 0.012

    private(set) var offset: Float?
    private(set) var sampleCount = 0
    private(set) var isStable = false

    /// Recent accepted distances, for the agreement test.
    private var recentOffsets: [Float] = []

    /// Enough to lock on if the search times out — worse than a settled estimate, but
    /// still a measured one.
    var canProduceDegradedResult: Bool { sampleCount >= Self.samplesForDegradedLock }

    func reset() {
        offset = nil
        sampleCount = 0
        isStable = false
        recentOffsets.removeAll()
    }

    /// Folds a distance measurement into the running estimate.
    func adopt(_ value: Float) {
        if let current = offset {
            offset = current + (value - current) * Self.blend
        } else {
            offset = value
        }

        sampleCount += 1
        recentOffsets.append(value)
        if recentOffsets.count > Self.agreementWindow {
            recentOffsets.removeFirst(recentOffsets.count - Self.agreementWindow)
        }
        refreshStability()
    }

    /// Whether recent distance measurements agree with each other.
    private func refreshStability() {
        guard recentOffsets.count >= Self.samplesForStability else {
            isStable = false
            return
        }
        // Signed, not absolute: the world origin is wherever the session started, so a
        // plane's offset is routinely negative and folding it would hide spread.
        guard let low = recentOffsets.min(), let high = recentOffsets.max() else { return }
        isStable = (high - low) <= Self.stabilityTolerance
    }
}
