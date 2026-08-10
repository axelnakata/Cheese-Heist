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

    /// Rope speed clamped by minLiftDuration.
    /// minLiftDuration clamps SPEED, never the ratio or the sign.
    /// v ≤ liftHeight / minLiftDuration, evaluated once against the full height.
    static func clampedRopeSpeed(
        rawSpeed: Double, tuning: LevelTuning
    ) -> Double {
        let maxSpeed = tuning.liftHeight / tuning.minLiftDuration
        return min(rawSpeed, maxSpeed)
    }

    /// Height integration: h(t+dt) = min(h(t) + v_rope · dt, ceiling)
    static func advanceHeight(
        currentHeight: Double, ropeSpeed: Double, deltaTime: Double, ceiling: Double
    ) -> Double {
        min(currentHeight + ropeSpeed * deltaTime, ceiling)
    }
}
