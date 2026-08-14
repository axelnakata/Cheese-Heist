// GearRatioCalculator.swift — Cheese Heist
// PRD §6.2 — pure functions for gear ratio, angular velocities, torques.

import Foundation

enum GearRatioCalculator {

    /// N_follower / N_driver.
    static func ratio(pair: GearPair) -> Double {
        Double(pair.follower.teeth) / Double(pair.driver.teeth)
    }

    /// τ_follower = τ_driver · i · η
    static func followerTorque(
        driverTorque: Double, ratio: Double, efficiency: Double
    ) -> Double {
        driverTorque * ratio * efficiency
    }

    /// Reciprocal identity: i(a,b) · i(b,a) == 1.
    static func reciprocalRatio(pair: GearPair) -> Double {
        ratio(pair: pair) * ratio(pair: pair.swapped)
    }
}
