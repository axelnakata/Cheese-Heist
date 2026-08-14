// Level1LiftDurations.swift — Cheese Heist
// PRD-Level1 §6 — how long a full lift takes, by gear combination.
//
// Level 1 is unfailable, so every combo has a duration — never nil. Tiered by DRIVER
// identity only, independent of the follower: the same small-driver/large-driver lesson
// regardless of what it's paired with. A small driver has a big mechanical advantage —
// strong but slow; a large driver has little advantage — weak but fast.

import Foundation

enum Level1LiftDurations {

    /// Seconds for a full lift with this pair, on any crane height.
    static func duration(for pair: GearPair) -> Double {
        switch pair.driver {
        case .eightTooth: return 7.0
        case .twentyFourTooth: return 5.0
        case .fortyTooth: return 3.0
        }
    }
}
