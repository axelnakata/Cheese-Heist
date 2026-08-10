//
//  SceneLayoutFromAssignment.swift
//  Cheese Heist
//
//  Assignment in, crane-local positions out. Pure.
//
//  THIS TYPE IS WHY NO `if the small gear is the driver` BRANCH EXISTS ANYWHERE IN THE
//  CODEBASE. The mouse perches on whichever gear is the driver and the rope hangs from
//  whichever is the follower, and both facts are one lookup rather than a condition
//  repeated in the coordinator, the director and the projector.
//
//  It is also what makes the role swap in `selectingRoles` a data change: tapping the
//  other gear produces a different assignment, this produces a different layout, and
//  the coordinator animates between the two. Nothing re-decides anything.
//

import Foundation
import simd

/// One gear, as placed in the crane's own coordinates.
struct GearPlacement: Equatable, Sendable {
    let id: UUID
    let type: GearType
    /// Crane-local. Z is ~0 by construction — the gears were solved as ray/plane hits
    /// on this very plane — so callers flatten it rather than carry float noise.
    let local: simd_float3
}

/// Where everything sits, in crane-local coordinates.
struct SceneLayout: Equatable, Sendable {
    let driver: GearPlacement
    let follower: GearPlacement

    /// The mouse's feet, on the driver gear's rim.
    let mousePerch: simd_float3

    /// The top of the rope, at the follower gear's axle.
    let ropeAnchor: simd_float3
}

enum SceneLayoutFromAssignment {

    /// Builds the layout for one assignment, or nil if the assignment does not name
    /// these two gears.
    static func layout(
        gears: [GearPlacement],
        assignment: GearRoleAssignment,
        mouseHeight: Float
    ) -> SceneLayout? {
        guard let driver = gears.first(where: { $0.id == assignment.driverID }),
              let follower = gears.first(where: { $0.id == assignment.followerID })
        else { return nil }

        return SceneLayout(
            driver: driver,
            follower: follower,
            mousePerch: perch(on: driver, mouseHeight: mouseHeight),
            ropeAnchor: follower.local
        )
    }

    /// How far above the driver gear's CENTRE the mouse stands.
    ///
    /// Derived from the gear, because the gear's size is the whole point of the lesson:
    /// an 8T is 10mm across and a 40T is 42mm. One fixed clearance puts the mouse
    /// buried in the 40T's teeth or floating a centimetre over the 8T, depending on
    /// which the child picked — and the child picks a different one every run.
    static func perch(on driver: GearPlacement, mouseHeight: Float) -> simd_float3 {
        driver.local + simd_float3(
            0, GearGeometry.tipRadius(of: driver.type) + mouseHeight / 2, 0
        )
    }
}
