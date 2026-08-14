//
//  ActuatorModelTests.swift
//  CheeseHeistTests
//
//  PRD §12.1 — no-load speed, the stall boundary, and the fact that omega never goes
//  negative.
//

import Testing
@testable import Cheese_Heist

struct ActuatorModelTests {

    let tuning = Level1Tuning.value

    @Test("an unloaded train turns at the no-load speed")
    func noLoad() {
        let unloaded = LevelTuning(
            payloadMass: 0,
            stallTorque: tuning.stallTorque,
            noLoadAngularVelocity: tuning.noLoadAngularVelocity,
            meshEfficiency: tuning.meshEfficiency,
            winchRadius: tuning.winchRadius,
            liftHeight: tuning.liftHeight
        )

        let omega = ActuatorModel.driverAngularVelocity(ratio: 1, tuning: unloaded)
        #expect(abs(omega - unloaded.noLoadAngularVelocity) < 1e-12)
    }

    /// At the stall boundary the available torque exactly equals the load, so the
    /// train holds without turning — it must not turn backwards.
    @Test("omega is clamped at zero, never negative")
    func neverNegative() {
        let overloaded = LevelTuning(
            payloadMass: 10,               // absurd on purpose
            stallTorque: tuning.stallTorque,
            noLoadAngularVelocity: tuning.noLoadAngularVelocity,
            meshEfficiency: tuning.meshEfficiency,
            winchRadius: tuning.winchRadius,
            liftHeight: tuning.liftHeight
        )

        for pair in GearRatioCalculatorTests.allPairs {
            let omega = ActuatorModel.driverAngularVelocity(ratio: pair.ratio, tuning: overloaded)
            #expect(omega == 0)
        }
    }

    @Test("gearing up raises the available torque, so a heavier load still lifts")
    func gearingRaisesCapacity() {
        let heavy = LevelTuning(
            payloadMass: 0.08,
            stallTorque: tuning.stallTorque,
            noLoadAngularVelocity: tuning.noLoadAngularVelocity,
            meshEfficiency: tuning.meshEfficiency,
            winchRadius: tuning.winchRadius,
            liftHeight: tuning.liftHeight
        )

        let gearedUp = GearPair(driver: .eightTooth, follower: .fortyTooth)
        let gearedDown = GearPair(driver: .fortyTooth, follower: .eightTooth)

        #expect(ActuatorModel.canLift(ratio: gearedUp.ratio, tuning: heavy))
        #expect(!ActuatorModel.canLift(ratio: gearedDown.ratio, tuning: heavy))
    }

    /// Level 1 is unfailable by design — the child cannot pick a losing pair.
    @Test("every Level 1 pair lifts")
    func level1IsUnfailable() {
        #expect(LiftFeasibilityEvaluator.allPairsSucceed(gears: GearType.allCases))
    }
}
