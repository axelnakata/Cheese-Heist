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

    /// The mouse's feet, standing on the beam just behind the driver gear.
    let mousePerch: simd_float3

    /// The top of the rope, at the follower gear's axle.
    let ropeAnchor: simd_float3
}

enum SceneLayoutFromAssignment {

    /// Builds the layout for one assignment, or nil if the assignment does not name
    /// these two gears.
    static func layout(
        gears: [GearPlacement],
        assignment: GearRoleAssignment
    ) -> SceneLayout? {
        guard let driver = gears.first(where: { $0.id == assignment.driverID }),
              let follower = gears.first(where: { $0.id == assignment.followerID })
        else { return nil }

        return SceneLayout(
            driver: driver,
            follower: follower,
            mousePerch: perch(on: driver),
            ropeAnchor: follower.local
        )
    }

    /// Where the mouse stands: on the beam, tucked in close behind the driver gear
    /// rather than riding on top of it.
    ///
    /// Both offsets are the driver's own tip radius — derived from the gear, because
    /// the gear's size is the whole point of the lesson: an 8T is 10mm across and a
    /// 40T is 42mm. One fixed clearance either leaves the mouse buried in the 40T's
    /// teeth or standing a whole gear's width off the 8T, depending on which the child
    /// picked, and the child picks a different one every run. UP puts its feet level
    /// with the gear's rim, roughly where the beam actually is; BACK (−Z, away from the
    /// camera — see `CraneFrame`) clears the disc's teeth without wandering off to the
    /// side of the gear it is meant to be standing behind.
    static func perch(on driver: GearPlacement) -> simd_float3 {
        let radius = GearGeometry.tipRadius(of: driver.type)
        return driver.local + simd_float3(0, radius, -radius)
    }
}
