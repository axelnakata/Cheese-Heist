// GearRole.swift — Cheese Heist
// PRD §6 — driver is turned by the actuator, follower is turned by the driver.

enum GearRole: String, CaseIterable, Hashable, Sendable {
    case driver
    case follower

    var opposite: GearRole {
        self == .driver ? .follower : .driver
    }
}
