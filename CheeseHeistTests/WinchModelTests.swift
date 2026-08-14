//
//  WinchModelTests.swift
//  CheeseHeistTests
//
//  Total lift duration is a designed property of the gear combination, not of crane
//  height — `designedRopeSpeed` is the single formula that makes that true.
//

import Testing
@testable import Cheese_Heist

struct WinchModelTests {

    @Test("designed speed is height over duration")
    func speedIsHeightOverDuration() {
        #expect(WinchModel.designedRopeSpeed(liftHeight: 0.10, duration: 5) == 0.02)
    }

    /// The whole point of the feature: two cranes of different height, same gear pair,
    /// finish at the same instant — only the rope speed differs.
    @Test("the same duration at two different heights finishes in the same time, at different speeds")
    func heightIndependentDuration() {
        let duration = 5.0
        let shortCrane = WinchModel.designedRopeSpeed(liftHeight: 0.05, duration: duration)
        let tallCrane = WinchModel.designedRopeSpeed(liftHeight: 0.25, duration: duration)

        #expect(tallCrane > shortCrane)
        #expect(0.05 / shortCrane == duration)
        #expect(0.25 / tallCrane == duration)
    }

    @Test("a non-positive duration yields no speed rather than dividing by zero or going negative")
    func nonPositiveDurationIsZeroSpeed() {
        #expect(WinchModel.designedRopeSpeed(liftHeight: 0.10, duration: 0) == 0)
        #expect(WinchModel.designedRopeSpeed(liftHeight: 0.10, duration: -1) == 0)
    }

    @Test("height never decreases and never passes the ceiling")
    func monotonicAndClamped() {
        var height: Double = 0
        let ceiling = Level1Tuning.value.liftHeight

        for _ in 0..<1_000 {
            let next = WinchModel.advanceHeight(
                currentHeight: height, ropeSpeed: 0.01, deltaTime: 1.0 / 60, ceiling: ceiling
            )
            #expect(next >= height)
            #expect(next <= ceiling)
            height = next
        }

        #expect(height == ceiling)
    }
}
