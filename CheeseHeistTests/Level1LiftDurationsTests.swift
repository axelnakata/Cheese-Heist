//
//  Level1LiftDurationsTests.swift
//  CheeseHeistTests
//
//  Level 1 is unfailable — every combo must have a duration, tiered by driver identity.
//

import Testing
@testable import Cheese_Heist

struct Level1LiftDurationsTests {

    @Test("every driver/follower combination has a duration")
    func allCombosHaveADuration() {
        for driver in GearType.allCases {
            for follower in GearType.allCases {
                let pair = GearPair(driver: driver, follower: follower)
                #expect(Level1LiftDurations.duration(for: pair) > 0)
            }
        }
    }

    @Test("duration is tiered by driver identity, independent of the follower")
    func durationIsDriverTiered() {
        for follower in GearType.allCases {
            #expect(Level1LiftDurations.duration(for: GearPair(driver: .eightTooth, follower: follower)) == 7.0)
            #expect(Level1LiftDurations.duration(for: GearPair(driver: .twentyFourTooth, follower: follower)) == 5.0)
            #expect(Level1LiftDurations.duration(for: GearPair(driver: .fortyTooth, follower: follower)) == 3.0)
        }
    }
}
