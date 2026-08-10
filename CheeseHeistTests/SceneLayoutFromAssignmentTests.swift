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
    let mouseHeight: Float = 0.055

    private var gears: [GearPlacement] { [small, large] }

    private func layout(driver: GearPlacement, follower: GearPlacement) -> SceneLayout? {
        SceneLayoutFromAssignment.layout(
            gears: gears,
            assignment: GearRoleAssignment(driverID: driver.id, followerID: follower.id),
            mouseHeight: mouseHeight
        )
    }

    @Test("the rope hangs from whichever gear is the follower")
    func ropeFollowsTheFollower() {
        #expect(layout(driver: small, follower: large)?.ropeAnchor == large.local)
        #expect(layout(driver: large, follower: small)?.ropeAnchor == small.local)
    }

    /// A fixed clearance buries the mouse in a 40T's teeth or floats it a centimetre
    /// over an 8T, and the child picks a different gear every run.
    @Test("the mouse's perch is derived from the driver's own size")
    func perchScalesWithTheDriver() {
        let onSmall = layout(driver: small, follower: large)
        let onLarge = layout(driver: large, follower: small)

        let smallExpected = small.local.y
            + GearGeometry.tipRadius(of: .eightTooth) + mouseHeight / 2
        let largeExpected = large.local.y
            + GearGeometry.tipRadius(of: .fortyTooth) + mouseHeight / 2

        #expect(onSmall?.mousePerch.y == smallExpected)
        #expect(onLarge?.mousePerch.y == largeExpected)
        #expect(largeExpected > smallExpected)
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
        #expect(SceneLayoutFromAssignment.layout(
            gears: gears, assignment: stray, mouseHeight: mouseHeight
        ) == nil)
    }
}
