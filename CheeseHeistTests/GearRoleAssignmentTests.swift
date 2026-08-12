//
//  GearRoleAssignmentTests.swift
//  CheeseHeistTests
//
//  PRD §12.1 — `swapped()` is involutive.
//

import Foundation
import Testing
@testable import Cheese_Heist

struct GearRoleAssignmentTests {

    let driver = UUID()
    let follower = UUID()

    private var assignment: GearRoleAssignment {
        GearRoleAssignment(driverID: driver, followerID: follower)
    }

    @Test("swapping twice is the identity")
    func swapIsInvolutive() {
        #expect(assignment.swapped.swapped == assignment)
    }

    @Test("swapping exchanges the two roles")
    func swapExchangesRoles() {
        let swapped = assignment.swapped
        #expect(swapped.driverID == follower)
        #expect(swapped.followerID == driver)
    }

    @Test("role lookup answers only for gears in the pair")
    func roleLookup() {
        #expect(assignment.role(of: driver) == .driver)
        #expect(assignment.role(of: follower) == .follower)
        #expect(assignment.role(of: UUID()) == nil)
    }

    /// Tapping the gear that is already the driver changes nothing — the child
    /// re-confirming their choice must not animate a swap.
    @Test("assigning the current driver is a no-op")
    func assigningCurrentDriverIsIdempotent() {
        #expect(assignment.assigningDriver(driver) == assignment)
    }

    @Test("assigning the follower swaps the pair")
    func assigningFollowerSwaps() {
        #expect(assignment.assigningDriver(follower) == assignment.swapped)
    }

    @Test("a gear outside the pair cannot be assigned")
    func unknownGearIsRejected() {
        #expect(assignment.assigningDriver(UUID()) == nil)
    }
}
