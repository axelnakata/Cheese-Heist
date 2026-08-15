// GearTrainSimulator.swift — Cheese Heist
// PRD §6 + §11.5.8 — integrates the gear train state per tick.

import Foundation

enum GearTrainSimulator {

    /// Advances the gear train by one tick.
    ///
    /// Per-frame loop:
    /// 1. drive       ← CrankInputViewModel (.holding freezes; .rising and .falling
    ///    run the identical integrator with the sign flipped)
    /// 2. ω_driver    ← ActuatorModel — drives the cosmetic spin only
    /// 3. ω_follower  ← −ω_driver / i
    /// 4. driverAngle += ±ω_driver · dt
    /// 5. liftDuration ← nil means this pair can't lift → `.stalled` while rising
    /// 6. v_rope      ← liftHeight / liftDuration (`WinchModel.designedRopeSpeed`)
    /// 7. height      ← height ± v_rope·dt, clamped to [0, ceiling]
    /// 8. if height == ceiling while rising → .reachedCeiling
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

        switch state.drive {
        case .holding:
            // Ratchet: holding steady means no back-drive, so the cheese holds height.
            return nil

        case .rising:
            guard let liftDuration else { return .stalled }

            let ratio = pair.ratio
            let omegaDriver = ActuatorModel.driverAngularVelocity(ratio: ratio, tuning: tuning)
            state.driverAngle += omegaDriver * dt

            let ceiling = tuning.liftHeight * segment.ceilingFraction
            let ropeSpeed = WinchModel.designedRopeSpeed(
                liftHeight: tuning.liftHeight, duration: liftDuration
            )
            state.height = WinchModel.advanceHeight(
                currentHeight: state.height, ropeSpeed: ropeSpeed, deltaTime: dt, ceiling: ceiling
            )

            return state.height >= ceiling ? .reachedCeiling : nil

        case .falling:
            // Letting go or cranking backwards unwinds the rope the mouse just wound —
            // the same integrator run in reverse, floored at the table rather than
            // ceilinged at the segment. A pair with no duration table entry never left
            // the table in the first place, so there is nothing to unwind.
            guard state.height > 0, let liftDuration else { return nil }

            let ratio = pair.ratio
            let omegaDriver = ActuatorModel.driverAngularVelocity(ratio: ratio, tuning: tuning)
            state.driverAngle -= omegaDriver * dt

            let ropeSpeed = WinchModel.designedRopeSpeed(
                liftHeight: tuning.liftHeight, duration: liftDuration
            )
            state.height = WinchModel.retractHeight(
                currentHeight: state.height, ropeSpeed: ropeSpeed, deltaTime: dt
            )

            return nil
        }
    }

    /// Resets the simulation state for a new run.
    static func reset(state: inout GearTrainState) {
        state.driverAngle = 0
        state.height = 0
        state.drive = .holding
    }
}
