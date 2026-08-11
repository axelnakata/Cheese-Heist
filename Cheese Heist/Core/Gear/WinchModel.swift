// WinchModel.swift — Cheese Heist
// PRD §6.3 — rope wound on the follower gear's axle.

import Foundation

enum WinchModel {

    /// v_rope = |ω_follower| · r_drum
    static func ropeSpeed(
        followerAngularVelocity: Double, winchRadius: Double
    ) -> Double {
        abs(followerAngularVelocity) * winchRadius
    }

    /// Rope speed held between the two presentation bounds.
    ///
    /// Both clamp SPEED, never the ratio or the sign, and both are evaluated once
    /// against the full height so no per-segment special case exists:
    ///
    ///     liftHeight / maxLiftDuration  ≤  v  ≤  liftHeight / minLiftDuration
    ///
    /// The upper bound stops the fast pairing finishing before the child has seen it
    /// move. The lower bound stops the slow pairing on a long rope taking most of a
    /// minute — `liftHeight` is measured off the crane now, so its range is the child's
    /// to decide and something has to bound it.
    static func clampedRopeSpeed(
        rawSpeed: Double, tuning: LevelTuning
    ) -> Double {
        let fastest = tuning.liftHeight / tuning.minLiftDuration
        let slowest = tuning.liftHeight / tuning.maxLiftDuration
        return min(max(rawSpeed, slowest), fastest)
    }

    /// Height integration: h(t+dt) = min(h(t) + v_rope · dt, ceiling)
    static func advanceHeight(
        currentHeight: Double, ropeSpeed: Double, deltaTime: Double, ceiling: Double
    ) -> Double {
        min(currentHeight + ropeSpeed * deltaTime, ceiling)
    }
}
