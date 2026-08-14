//
//  Level2OutcomeEvaluatorTests.swift
//  CheeseHeistTests
//
//  Tests for Level 2 gear outcome evaluation and star counting.
//
//  Exercises the full hardcoded balance table for all 6 live combos: canLift, bars,
//  duration, and the resulting star/fail classification once the duration is compared
//  against the 15-second timer.
//

import XCTest
@testable import Cheese_Heist

final class Level2OutcomeEvaluatorTests: XCTestCase {

    private func timeRemaining(afterLiftDuration duration: Double?) -> Int? {
        guard let duration else { return nil }
        return Int(Double(Level2Tuning.timerDuration) - duration)
    }

    func testWeakestCombinationStallsImmediately() {
        // 40T driver, 8T follower — the only combo below the torque floor.
        let outcome = Level2GearOutcomeEvaluator.evaluate(
            pair: GearPair(driver: .fortyTooth, follower: .eightTooth)
        )

        XCTAssertFalse(outcome.canLift)
        XCTAssertNil(outcome.estimatedLiftTime)
        XCTAssertEqual(outcome.strengthLevel, 1)
        XCTAssertEqual(outcome.speedLevel, 3)
    }

    func testStrongestCombinationLiftsButRunsOutTheClock() {
        // 8T driver, 40T follower — the most torque, and the slowest: 17s > the 15s timer.
        let outcome = Level2GearOutcomeEvaluator.evaluate(
            pair: GearPair(driver: .eightTooth, follower: .fortyTooth)
        )

        XCTAssertTrue(outcome.canLift)
        XCTAssertEqual(outcome.estimatedLiftTime, 17.0)
        XCTAssertEqual(outcome.strengthLevel, 3)
        XCTAssertEqual(outcome.speedLevel, 1)
        XCTAssertEqual(Level2GearOutcomeEvaluator.starCount(
            timeRemaining: timeRemaining(afterLiftDuration: outcome.estimatedLiftTime) ?? 0
        ), 0)
    }

    /// Every live combo's outcome, matched against the balance table in
    /// `Level2GearOutcome.swift`'s header comment.
    func testFullBalanceTable() {
        let expectations:
            [(driver: GearType, follower: GearType, canLift: Bool, duration: Double?, stars: Int)] = [
                (.fortyTooth, .eightTooth, false, nil, 0),
                (.twentyFourTooth, .eightTooth, true, 3.0, 3),
                (.fortyTooth, .twentyFourTooth, true, 4.0, 3),
                (.twentyFourTooth, .fortyTooth, true, 8.0, 2),
                (.eightTooth, .twentyFourTooth, true, 12.0, 1),
                (.eightTooth, .fortyTooth, true, 17.0, 0),
            ]

        for expectation in expectations {
            let pair = GearPair(driver: expectation.driver, follower: expectation.follower)
            let outcome = Level2GearOutcomeEvaluator.evaluate(pair: pair)

            XCTAssertEqual(outcome.canLift, expectation.canLift, "\(pair)")
            XCTAssertEqual(outcome.estimatedLiftTime, expectation.duration, "\(pair)")

            let remaining = timeRemaining(afterLiftDuration: outcome.estimatedLiftTime) ?? 0
            let stars = outcome.canLift
                ? Level2GearOutcomeEvaluator.starCount(timeRemaining: remaining)
                : 0
            XCTAssertEqual(stars, expectation.stars, "\(pair)")
        }
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
