// GearPair.swift — Cheese Heist
// PRD §6 — an ordered pair of gears with assigned roles.

struct GearPair: Equatable, Sendable {
    let driver: GearType
    let follower: GearType

    /// N_follower / N_driver.
    var ratio: Double {
        Double(follower.teeth) / Double(driver.teeth)
    }

    /// Swaps roles: the driver becomes follower and vice versa.
    var swapped: GearPair {
        GearPair(driver: follower, follower: driver)
    }

    /// Module-1 meshing centre distance, in metres.
    var meshDistance: Double {
        GearType.meshDistance(driver, follower)
    }
}
