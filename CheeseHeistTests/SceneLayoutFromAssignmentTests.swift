//
//  SceneLayoutFromAssignmentTests.swift
//  CheeseHeistTests
//
//  PRD §12.1 — the layout derives purely from the assignment.
//
//  This is the test that guarantees no `if the small gear is the driver` branch exists
//  anywhere in the codebase: the mouse and the rope follow the ROLES, and swapping the
//  roles swaps where they sit without anything else changing.
//

import Foundation
import Testing
import simd
@testable import Cheese_Heist

struct SceneLayoutFromAssignmentTests {

    let small = GearPlacement(
        id: UUID(), type: .eightTooth, local: simd_float3(-0.012, 0, 0)
    )
    let large = GearPlacement(
        id: UUID(), type: .fortyTooth, local: simd_float3(0.012, 0, 0)
    )

    private var gears: [GearPlacement] { [small, large] }

    private func layout(driver: GearPlacement, follower: GearPlacement) -> SceneLayout? {
        SceneLayoutFromAssignment.layout(
            gears: gears,
            assignment: GearRoleAssignment(driverID: driver.id, followerID: follower.id)
        )
    }

    @Test("the rope hangs from whichever gear is the follower")
    func ropeFollowsTheFollower() {
        #expect(layout(driver: small, follower: large)?.ropeAnchor == large.local)
        #expect(layout(driver: large, follower: small)?.ropeAnchor == small.local)
    }

    /// A fixed clearance buries the mouse in a 40T's teeth or floats it a centimetre
    /// over an 8T, and the child picks a different gear every run.
    @Test("the mouse's clearance behind the driver is derived from the driver's own size")
    func clearanceScalesWithTheDriver() {
        let onSmall = layout(driver: small, follower: large)
        let onLarge = layout(driver: large, follower: small)

        let smallRadius = GearGeometry.tipRadius(of: .eightTooth)
        let largeRadius = GearGeometry.tipRadius(of: .fortyTooth)

        // BEHIND the driver, not centred on it — away from the camera along local -Z.
        #expect(onSmall?.mousePerch.z == small.local.z - smallRadius)
        #expect(onLarge?.mousePerch.z == large.local.z - largeRadius)
        #expect((onLarge?.mousePerch.z ?? 0) < (onSmall?.mousePerch.z ?? 0))
    }

    /// The regression this replaced: the perch's height used to be the driver's tip
    /// radius, which is the RIM. The gear is mounted through the beam, so its rim is a
    /// whole radius above the surface the mouse is supposed to be standing on — 21mm of
    /// thin air on a 40T. Height is the beam, and the beam does not change size.
    @Test("the mouse stands on the beam, at the same height whichever gear drives")
    func perchStandsOnTheBeam() {
        let onSmall = layout(driver: small, follower: large)
        let onLarge = layout(driver: large, follower: small)

        #expect(onSmall?.mousePerch.y == small.local.y + GearGeometry.beamHalfHeight)
        #expect(onLarge?.mousePerch.y == large.local.y + GearGeometry.beamHalfHeight)
        #expect(onLarge?.mousePerch.y == onSmall?.mousePerch.y)

        // Well under the 40T's rim, which is where it used to float.
        #expect((onLarge?.mousePerch.y ?? 0) < large.local.y + GearGeometry.tipRadius(of: .fortyTooth))
    }

    /// Swapping the assignment must move the mouse and the rope and nothing else.
    @Test("the layout is a pure function of the assignment")
    func layoutIsPure() {
        let forward = layout(driver: small, follower: large)
        let backward = layout(driver: large, follower: small)

        #expect(forward?.driver.id == small.id)
        #expect(backward?.driver.id == large.id)
        #expect(forward?.driver.local == backward?.follower.local)
        #expect(forward?.follower.local == backward?.driver.local)
    }

    @Test("the same assignment always yields the same layout")
    func repeatable() {
        #expect(layout(driver: small, follower: large) == layout(driver: small, follower: large))
    }

    @Test("an assignment naming a gear that is not here yields nothing")
    func unknownGearYieldsNil() {
        let stray = GearRoleAssignment(driverID: UUID(), followerID: large.id)
        #expect(SceneLayoutFromAssignment.layout(gears: gears, assignment: stray) == nil)
    }
}
