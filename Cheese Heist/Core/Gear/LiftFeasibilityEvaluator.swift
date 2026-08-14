// LiftFeasibilityEvaluator.swift — Cheese Heist
// PRD §6.4 — can this pair lift at all?
//
// Level 1 is unfailable, so feasibility is exhaustiveness of `Level1LiftDurations`, not a
// torque formula — every combo the child can build must have a designed duration.

enum LiftFeasibilityEvaluator {

    /// Returns true iff Level 1's duration table has a duration for this pair.
    static func canLift(pair: GearPair) -> Bool {
        Level1LiftDurations.duration(for: pair) > 0
    }

    /// Checks every ordered pair of the given gear types.
    /// Level 1 requires ALL pairs to succeed (LO-3 not yet taught).
    static func allPairsSucceed(gears: [GearType]) -> Bool {
        for driver in gears {
            for follower in gears {
                let pair = GearPair(driver: driver, follower: follower)
                if !canLift(pair: pair) { return false }
            }
        }
        return true
    }
}
