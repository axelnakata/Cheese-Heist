// Level2GearOutcome.swift — Cheese Heist
// PRD-Level2 §5 — hardcoded outcome for each driver/follower assignment.
// The bars and lift feasibility are pure functions of the ratio.

import Foundation

/// The predicted outcome for a given driver/follower gear choice in Level 2.
struct Level2GearOutcome: Equatable, Sendable {

    /// Whether the mouse can lift the cheese at all (i · η · τ_stall > τ_load).
    let canLift: Bool

    /// How many bars to fill on the strength indicator (1–4).
    let strengthLevel: Int

    /// How many bars to fill on the speed indicator (1–4).
    let speedLevel: Int

    /// Approximate lift time in seconds, or nil if the combo stalls.
    let estimatedLiftTime: Double?
}

enum Level2GearOutcomeEvaluator {

    /// Computes the outcome for a driver/follower pair at Level 2 tuning.
    static func evaluate(pair: GearPair) -> Level2GearOutcome {
        evaluate(pair: pair, tuning: Level2Tuning.value)
    }

    /// Testable variant that accepts arbitrary tuning.
    static func evaluate(pair: GearPair, tuning: LevelTuning) -> Level2GearOutcome {
        let ratio = pair.ratio
        let canLift = ActuatorModel.canLift(ratio: ratio, tuning: tuning)

        let strength = strengthLevel(for: ratio)
        let speed = speedLevel(for: ratio)

        var liftTime: Double?
        if canLift {
            liftTime = estimatedLiftTime(ratio: ratio, tuning: tuning)
        }

        return Level2GearOutcome(
            canLift: canLift,
            strengthLevel: strength,
            speedLevel: speed,
            estimatedLiftTime: liftTime
        )
    }

    // MARK: - Star count

    /// How many cheese the child earns from the time they had left.
    /// PRD-Level2 §5.3: ≥10s → 3, ≥5s → 2, >0s → 1, else 0.
    static func starCount(timeRemaining: Int) -> Int {
        if timeRemaining >= 10 { return 3 }
        if timeRemaining >= 5 { return 2 }
        if timeRemaining > 0 { return 1 }
        return 0
    }

    /// How many cheese should still appear solid at this moment.
    /// PRD-Level2 §4.2: 15–10s → 3, 9–5s → 2, 4–1s → 1, 0s → 0.
    static func solidCheeseCount(timeRemaining: Int) -> Int {
        starCount(timeRemaining: timeRemaining)
    }

    // MARK: - Bar levels

    /// Strength is proportional to the gear ratio — higher ratio means more torque
    /// multiplication, so the mouse is "stronger". PRD-Level2 §5.5.
    static func strengthLevel(for ratio: Double) -> Int {
        if ratio >= 4.0 { return 4 }
        if ratio >= 2.0 { return 3 }
        if ratio >= 0.5 { return 2 }
        return 1
    }

    /// Speed is inversely proportional to the ratio — lower ratio means the follower
    /// spins faster. PRD-Level2 §5.5.
    static func speedLevel(for ratio: Double) -> Int {
        if ratio < 0.5 { return 4 }
        if ratio < 2.0 { return 3 }
        if ratio < 4.0 { return 2 }
        return 1
    }

    // MARK: - Lift time

    private static func estimatedLiftTime(ratio: Double, tuning: LevelTuning) -> Double {
        let omegaDriver = ActuatorModel.driverAngularVelocity(ratio: ratio, tuning: tuning)
        guard omegaDriver > 0 else { return .infinity }

        let omegaFollower = GearRatioCalculator.followerAngularVelocity(
            driverAngularVelocity: omegaDriver, ratio: ratio
        )
        let rawSpeed = WinchModel.ropeSpeed(
            followerAngularVelocity: omegaFollower, winchRadius: tuning.winchRadius
        )
        let speed = WinchModel.clampedRopeSpeed(rawSpeed: rawSpeed, tuning: tuning)
        guard speed > 0 else { return .infinity }

        return tuning.liftHeight / speed
    }
}
