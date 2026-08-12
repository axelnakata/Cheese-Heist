// LiftFeasibilityEvaluator.swift — Cheese Heist
// PRD §6.4 — can this pair lift at this tuning?

enum LiftFeasibilityEvaluator {

    /// Returns true iff i · η · τ_stall > τ_load.
    static func canLift(pair: GearPair, tuning: LevelTuning) -> Bool {
        ActuatorModel.canLift(ratio: pair.ratio, tuning: tuning)
    }

    /// Checks every ordered pair of the given gear types.
    /// Level 1 requires ALL pairs to succeed (LO-3 not yet taught).
    static func allPairsSucceed(
        gears: [GearType], tuning: LevelTuning
    ) -> Bool {
        for driver in gears {
            for follower in gears {
                let pair = GearPair(driver: driver, follower: follower)
                if !canLift(pair: pair, tuning: tuning) { return false }
            }
        }
        return true
    }
}
