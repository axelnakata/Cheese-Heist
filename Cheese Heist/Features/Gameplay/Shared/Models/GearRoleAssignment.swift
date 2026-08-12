//
//  GearRoleAssignment.swift
//  Cheese Heist
//
//  Which detected gear is the driver and which is the follower.
//
//  Identified by `UUID`, never by index or by tooth count. Ids are carried across
//  tracking updates (`GearTrackingPublisher`), so a role the child assigned survives
//  the estimate improving underneath it — and the ViewModel can hold an assignment
//  without importing ARKit or simd.
//

import Foundation

struct GearRoleAssignment: Equatable, Sendable {
    let driverID: UUID
    let followerID: UUID

    /// The same two gears with their roles exchanged.
    var swapped: GearRoleAssignment {
        GearRoleAssignment(driverID: followerID, followerID: driverID)
    }

    func role(of id: UUID) -> GearRole? {
        switch id {
        case driverID: return .driver
        case followerID: return .follower
        default: return nil
        }
    }

    func id(for role: GearRole) -> UUID {
        role == .driver ? driverID : followerID
    }

    /// Makes `id` the driver, and whichever of the two it is not the follower.
    /// Returns nil if `id` is not one of this pair.
    func assigningDriver(_ id: UUID) -> GearRoleAssignment? {
        switch id {
        case driverID: return self
        case followerID: return swapped
        default: return nil
        }
    }
}
