// GearTrainSimulator.swift — Cheese Heist
// PRD §6 + §11.5.8 — integrates the gear train state per tick.

import Foundation

enum GearTrainSimulator {

    /// Advances the gear train by one tick.
    ///
    /// Per-frame loop (§11.5.8):
    /// 1. isCranking ← CrankInputViewModel
    /// 2. ω_driver   ← ActuatorModel (0 if !isCranking)
    /// 3. ω_follower ← −ω_driver / i
    /// 4. driverAngle += ω_driver · dt
    /// 5. v_rope     ← |ω_follower| · r_drum (clamped by minLiftDuration)
    /// 6. height     ← min(height + v_rope·dt, ceiling)
    /// 7. if height == ceiling → .reachedCeiling
    static func advance(
        state: inout GearTrainState,
        pair: GearPair,
        tuning: LevelTuning,
        segment: LiftSegment,
        deltaTime: Double
    ) -> LiftOutcome? {
        let dt = min(max(deltaTime, 0), 0.1)
        guard dt > 0 else { return nil }

        // Ratchet: with no crank there is no back-drive, so the cheese holds height.
        guard state.isCranking else { return nil }

        let ratio = pair.ratio
        let omegaDriver = ActuatorModel.driverAngularVelocity(ratio: ratio, tuning: tuning)
        guard omegaDriver > 0 else { return .stalled }

        state.driverAngle += omegaDriver * dt

        let ceiling = tuning.liftHeight * segment.ceilingFraction
        state.height = WinchModel.advanceHeight(
            currentHeight: state.height,
            ropeSpeed: ropeSpeed(omegaDriver: omegaDriver, ratio: ratio, tuning: tuning),
            deltaTime: dt,
            ceiling: ceiling
        )

        return state.height >= ceiling ? .reachedCeiling : nil
    }

    /// Rope speed for this driver speed, after the presentation floor.
    ///
    /// `minLiftDuration` clamps the SPEED and never the ratio or the sign — it is
    /// evaluated once against the full height, so no per-segment special case exists.
    private static func ropeSpeed(
        omegaDriver: Double, ratio: Double, tuning: LevelTuning
    ) -> Double {
        let omegaFollower = GearRatioCalculator.followerAngularVelocity(
            driverAngularVelocity: omegaDriver, ratio: ratio
        )
        let raw = WinchModel.ropeSpeed(
            followerAngularVelocity: omegaFollower, winchRadius: tuning.winchRadius
        )
        return WinchModel.clampedRopeSpeed(rawSpeed: raw, tuning: tuning)
    }

    /// Resets the simulation state for a new run.
    static func reset(state: inout GearTrainState) {
        state.driverAngle = 0
        state.height = 0
        state.isCranking = false
    }
}
