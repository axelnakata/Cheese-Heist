// GearTrainSimulator.swift — Cheese Heist
// PRD §6 + §11.5.8 — integrates the gear train state per tick.

import Foundation

enum GearTrainSimulator {

    /// Advances the gear train by one tick.
    ///
    /// Per-frame loop:
    /// 1. isCranking  ← CrankInputViewModel
    /// 2. ω_driver    ← ActuatorModel (0 if !isCranking) — drives the cosmetic spin only
    /// 3. ω_follower  ← −ω_driver / i
    /// 4. driverAngle += ω_driver · dt
    /// 5. liftDuration ← nil means this pair can't lift → `.stalled`
    /// 6. v_rope      ← liftHeight / liftDuration (`WinchModel.designedRopeSpeed`)
    /// 7. height      ← min(height + v_rope·dt, ceiling)
    /// 8. if height == ceiling → .reachedCeiling
    static func advance(
        state: inout GearTrainState,
        pair: GearPair,
        tuning: LevelTuning,
        segment: LiftSegment,
        liftDuration: Double?,
        deltaTime: Double
    ) -> LiftOutcome? {
        let dt = min(max(deltaTime, 0), 0.1)
        guard dt > 0 else { return nil }

        // Ratchet: with no crank there is no back-drive, so the cheese holds height.
        guard state.isCranking else { return nil }

        guard let liftDuration else { return .stalled }

        let ratio = pair.ratio
        let omegaDriver = ActuatorModel.driverAngularVelocity(ratio: ratio, tuning: tuning)
        state.driverAngle += omegaDriver * dt

        let ceiling = tuning.liftHeight * segment.ceilingFraction
        let ropeSpeed = WinchModel.designedRopeSpeed(
            liftHeight: tuning.liftHeight, duration: liftDuration
        )
        state.height = WinchModel.advanceHeight(
            currentHeight: state.height,
            ropeSpeed: ropeSpeed,
            deltaTime: dt,
            ceiling: ceiling
        )

        return state.height >= ceiling ? .reachedCeiling : nil
    }

    /// Resets the simulation state for a new run.
    static func reset(state: inout GearTrainState) {
        state.driverAngle = 0
        state.height = 0
        state.isCranking = false
    }
}
