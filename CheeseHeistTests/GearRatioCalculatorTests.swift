//
//  GearRatioCalculatorTests.swift
//  CheeseHeistTests
//
//  PRD §12.1 — all nine ordered pairs, the sign flip, and the reciprocal identity.
//

import Testing
@testable import Cheese_Heist

struct GearRatioCalculatorTests {

    /// Every ordered pair, including the three like-for-like ones.
    static let allPairs: [GearPair] = GearType.allCases.flatMap { driver in
        GearType.allCases.map { GearPair(driver: driver, follower: $0) }
    }

    @Test("i = N_follower / N_driver for all nine ordered pairs")
    func ratioForEveryPair() {
        for pair in Self.allPairs {
            let expected = Double(pair.follower.teeth) / Double(pair.driver.teeth)
            #expect(GearRatioCalculator.ratio(pair: pair) == expected)
        }
    }

    @Test("i(a,b) · i(b,a) == 1")
    func reciprocalIdentity() {
        for pair in Self.allPairs {
            #expect(abs(GearRatioCalculator.reciprocalRatio(pair: pair) - 1) < 1e-12)
        }
    }

    /// Gearing UP means the follower turns slower than the driver; gearing down, faster.
    @Test("a bigger follower turns more slowly")
    func gearingDirection() {
        let gearedUp = GearPair(driver: .eightTooth, follower: .fortyTooth)
        let gearedDown = GearPair(driver: .fortyTooth, follower: .eightTooth)

        #expect(gearedUp.ratio == 5.0)
        #expect(gearedDown.ratio == 0.2)
    }

    @Test("swapping roles inverts the ratio")
    func swapInvertsRatio() {
        for pair in Self.allPairs {
            #expect(abs(pair.swapped.ratio - 1 / pair.ratio) < 1e-12)
        }
    }
}
