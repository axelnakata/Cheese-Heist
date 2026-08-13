//
//  Level2OutcomeEvaluatorTests.swift
//  CheeseHeistTests
//
//  Tests for Level 2 gear outcome evaluation and star counting.
//

import XCTest
@testable import Cheese_Heist

final class Level2OutcomeEvaluatorTests: XCTestCase {

    func testOutcomeEvaluationForSufficientTorque() {
        // Driver = 24t, Follower = 40t => ratio = 40 / 24 = 1.667 (> 1.0)
        let pair = GearPair(driver: .z24, follower: .z40)
        let outcome = Level2GearOutcomeEvaluator.evaluate(pair: pair)

        XCTAssertTrue(outcome.canLift, "24t -> 40t should be able to lift 120g payload")
        XCTAssertGreaterThanOrEqual(outcome.strengthLevel, 2)
    }

    func testOutcomeEvaluationForInsufficientTorque() {
        // Driver = 40t, Follower = 8t => ratio = 8 / 40 = 0.2 (< 1.0)
        let pair = GearPair(driver: .z40, follower: .z8)
        let outcome = Level2GearOutcomeEvaluator.evaluate(pair: pair)

        XCTAssertFalse(outcome.canLift, "40t -> 8t should stall under 120g payload")
        XCTAssertEqual(outcome.strengthLevel, 1)
    }

    func testSolidCheeseCountThresholds() {
        XCTAssertEqual(Level2GearOutcomeEvaluator.solidCheeseCount(timeRemaining: 15), 3)
        XCTAssertEqual(Level2GearOutcomeEvaluator.solidCheeseCount(timeRemaining: 10), 3)
        XCTAssertEqual(Level2GearOutcomeEvaluator.solidCheeseCount(timeRemaining: 9), 2)
        XCTAssertEqual(Level2GearOutcomeEvaluator.solidCheeseCount(timeRemaining: 5), 2)
        XCTAssertEqual(Level2GearOutcomeEvaluator.solidCheeseCount(timeRemaining: 4), 1)
        XCTAssertEqual(Level2GearOutcomeEvaluator.solidCheeseCount(timeRemaining: 0), 0)
    }
}
