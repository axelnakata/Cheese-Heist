// CraneAlignmentFilter.swift — Cheese Heist
// Port from gear-poc ARSimulationViewModel: correct(toward:) + smooth(deltaTime:).
// Separating measurement from animation is the whole point.

import simd
import os

final class CraneAlignmentFilter {

    private let tuning: CraneAlignmentTuning

    private var targetOrigin: simd_float3?
    private var targetHeading: Float = 0
    private var renderedOrigin: simd_float3 = .zero
    private var renderedHeading: Float = 0
    private var reseating = false
    private var reseatStreak = 0

    var currentPose: CranePose {
        CranePose(origin: renderedOrigin, heading: renderedHeading)
    }

    init(tuning: CraneAlignmentTuning = .standard) {
        self.tuning = tuning
    }

    /// Forgets the correction entirely. Called on teardown, before the scene it was
    /// correcting goes away — a stale target applied to a fresh scene would drag the
    /// new crane toward where the old one was.
    func reset() {
        targetOrigin = nil
        targetHeading = 0
        renderedOrigin = .zero
        renderedHeading = 0
        reseating = false
        reseatStreak = 0
    }

    // MARK: - Correct (measurement clock, ~6Hz)

    func correct(toward measured: CraneFrame, anchorInverse: simd_float4x4) {
        let localTransform = anchorInverse * measured.transform
        let measuredLocal = pose(of: localTransform)

        let offset = measuredLocal.origin - renderedOrigin
        let distance = simd_length(offset)
        let turn = AngleHelper.shortestDelta(from: renderedHeading, to: measuredLocal.heading)

        if distance > tuning.reseatDistance || abs(turn) > tuning.reseatAngle {
            reseatStreak += 1
            if reseatStreak >= tuning.reseatUpdates {
                reseatStreak = 0
                reseating = true
                Logger.crane.debug("Re-seating — \(distance * 1000, format: .fixed(precision: 0))mm out")
            }
        } else {
            reseatStreak = 0
        }

        targetOrigin = measuredLocal.origin
        targetHeading = measuredLocal.heading
    }

    // MARK: - Smooth (render clock, 60Hz)

    func smooth(deltaTime: Float) -> simd_float4x4? {
        guard let target = targetOrigin else { return nil }

        let dt = min(max(deltaTime, 0), 0.1)
        guard dt > 0 else { return nil }

        let offset = target - renderedOrigin
        let distance = simd_length(offset)
        let turn = AngleHelper.shortestDelta(from: renderedHeading, to: targetHeading)

        guard distance > tuning.settledDistance || abs(turn) > tuning.settledAngle else {
            reseating = false
            return nil
        }

        if reseating, distance < tuning.reseatDoneDistance, abs(turn) < tuning.reseatDoneAngle {
            reseating = false
        }

        let timeConstant = reseating ? tuning.reseatTimeConstant : tuning.correctionTimeConstant
        let driftLimit = reseating ? tuning.reseatDriftLimit : tuning.maximumDrift
        let turnLimit = reseating ? tuning.reseatTurnLimit : tuning.maximumTurn

        let gain = 1 - exp(-dt / timeConstant)

        if distance > 1e-6 {
            renderedOrigin += (offset / distance) * min(distance * gain, driftLimit * dt)
        }

        let step = min(abs(turn) * gain, turnLimit * dt)
        renderedHeading += (turn < 0 ? -step : step)

        return CraneFrame.make(origin: renderedOrigin, heading: renderedHeading).transform
    }

    // MARK: - Helpers

    private func pose(of world: simd_float4x4) -> (origin: simd_float3, heading: Float) {
        (
            simd_float3(world.columns.3.x, world.columns.3.y, world.columns.3.z),
            atan2(world.columns.2.x, world.columns.2.z)
        )
    }
}
