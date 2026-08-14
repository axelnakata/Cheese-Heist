// Level2GearOutcome.swift — Cheese Heist
// PRD-Level2 §5 — hardcoded outcome for each driver/follower assignment.
//
// Balance table, by exact combo (ratio i = follower.teeth / driver.teeth — higher i
// means more torque and proportionally slower output, as real gearing works):
//
//   Driver→Follower   i       canLift   duration   remaining@15s   outcome
//   40→8              0.2     NO        —          —               0★ too weak
//   24→8              0.333   yes       3s         12s              3★
//   40→24             0.6     yes       4s         11s              3★
//   24→40             1.667   yes       8s         7s               2★
//   8→24              3.0     yes       12s        3s               1★
//   8→40              5.0     yes       17s        (negative)       0★ too slow
//
// Bars are coarser than duration — tiered by DRIVER identity only, same rule as
// `Level1LiftDurations`: small driver = strong+slow, large driver = weak+fast.

import Foundation

/// The predicted outcome for a given driver/follower gear choice in Level 2.
struct Level2GearOutcome: Equatable, Sendable {

    /// Whether the mouse can lift the cheese at all.
    let canLift: Bool

    /// How many bars to fill on the strength indicator (1–3).
    let strengthLevel: Int

    /// How many bars to fill on the speed indicator (1–3).
    let speedLevel: Int

    /// Lift time in seconds, or nil if the combo stalls.
    let estimatedLiftTime: Double?
}

enum Level2GearOutcomeEvaluator {

    /// Computes the outcome for a driver/follower pair.
    static func evaluate(pair: GearPair) -> Level2GearOutcome {
        let (canLift, duration) = liftOutcome(for: pair)
        let bars = barLevels(forDriver: pair.driver)

        return Level2GearOutcome(
            canLift: canLift,
            strengthLevel: bars.strength,
            speedLevel: bars.speed,
            estimatedLiftTime: duration
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

    /// Strength/speed bars are a coarse, driver-only story — independent of which
    /// follower it's paired with. PRD-Level2 §5.5.
    private static func barLevels(forDriver driver: GearType) -> (strength: Int, speed: Int) {
        switch driver {
        case .eightTooth: return (3, 1)       // small driver — strong, slow
        case .twentyFourTooth: return (2, 2)  // medium driver — balanced
        case .fortyTooth: return (1, 3)       // large driver — weak, fast
        }
    }

    // MARK: - Lift outcome

    /// The hardcoded balance table (module header). Same-tooth pairs are unreachable in
    /// live play — detection never yields two gears of the same class — so the default
    /// case is defensive only.
    private static func liftOutcome(for pair: GearPair) -> (canLift: Bool, duration: Double?) {
        switch (pair.driver, pair.follower) {
        case (.fortyTooth, .eightTooth): return (false, nil)
        case (.twentyFourTooth, .eightTooth): return (true, 3.0)
        case (.fortyTooth, .twentyFourTooth): return (true, 4.0)
        case (.twentyFourTooth, .fortyTooth): return (true, 8.0)
        case (.eightTooth, .twentyFourTooth): return (true, 12.0)
        case (.eightTooth, .fortyTooth): return (true, 17.0)
        default: return (true, 5.0)
        }
    }
}
