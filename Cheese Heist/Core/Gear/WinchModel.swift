// WinchModel.swift — Cheese Heist
// PRD §6.3 — rope wound on the follower gear's axle.

import Foundation

enum WinchModel {

    /// Rope speed for a designed total lift duration.
    ///
    /// v = liftHeight / duration — the ONE authority on how fast the rope moves. Total
    /// time to clear the full height is a property of the gear combination (see
    /// `Level1LiftDurations`/`Level2GearOutcome`), never of the crane: `liftHeight` here
    /// is the crane's own measured travel, so a taller crane gets a proportionally
    /// faster rope and a shorter crane a proportionally slower one, but both finish in
    /// exactly `duration` seconds. This replaced a physics-derived speed clamped between
    /// `minLiftDuration`/`maxLiftDuration` — those bounds are gone because there is no
    /// raw speed left to clamp; the duration table both replaces the ceiling/floor.
    static func designedRopeSpeed(
        liftHeight: Double, duration: Double
    ) -> Double {
        guard duration > 0 else { return 0 }
        return liftHeight / duration
    }

    /// Height integration: h(t+dt) = min(h(t) + v_rope · dt, ceiling)
    static func advanceHeight(
        currentHeight: Double, ropeSpeed: Double, deltaTime: Double, ceiling: Double
    ) -> Double {
        min(currentHeight + ropeSpeed * deltaTime, ceiling)
    }

    /// Unwinding: h(t+dt) = max(h(t) − v_rope · dt, 0). The floor is the table the
    /// crane stands on — the rope cannot pay out further than it started.
    static func retractHeight(
        currentHeight: Double, ropeSpeed: Double, deltaTime: Double
    ) -> Double {
        max(currentHeight - ropeSpeed * deltaTime, 0)
    }
}
