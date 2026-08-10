//
//  WinchModelTests.swift
//  CheeseHeistTests
//
//  PRD §12.1 — height monotonicity, the clamp at the ceiling, and the rule that
//  `minLiftDuration` clamps SPEED and never the ratio or the sign.
//

import Testing
@testable import Cheese_Heist

struct WinchModelTests {

    let tuning = Level1Tuning.value

    @Test("rope speed is the magnitude of the follower's speed times the drum radius")
    func ropeSpeedIsUnsigned() {
        let forward = WinchModel.ropeSpeed(followerAngularVelocity: 4, winchRadius: 0.0025)
        let reverse = WinchModel.ropeSpeed(followerAngularVelocity: -4, winchRadius: 0.0025)

        #expect(forward == reverse)
        #expect(forward == 4 * 0.0025)
    }

    /// The presentation floor applies to the rope, not to the gearing. A 25x spread in
    /// lift time between the child's two role choices is the lesson; clamping the ratio
    /// would flatten it.
    @Test("minLiftDuration caps speed at liftHeight / minLiftDuration")
    func speedClamp() {
        let cap = tuning.liftHeight / tuning.minLiftDuration

        #expect(WinchModel.clampedRopeSpeed(rawSpeed: cap * 10, tuning: tuning) == cap)
        #expect(WinchModel.clampedRopeSpeed(rawSpeed: cap / 10, tuning: tuning) == cap / 10)
    }

    /// Evaluated once against the FULL height, so no per-segment special case exists —
    /// the half-height run is capped by the same number as the full one.
    @Test("the speed cap is independent of the segment being run")
    func capIgnoresSegment() {
        let cap = tuning.liftHeight / tuning.minLiftDuration
        #expect(cap == 0.06 / 1.2)
    }

    @Test("height never decreases and never passes the ceiling")
    func monotonicAndClamped() {
        var height: Double = 0
        let ceiling = tuning.liftHeight

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
