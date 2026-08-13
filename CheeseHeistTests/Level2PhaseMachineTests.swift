//
//  Level2PhaseMachineTests.swift
//  CheeseHeistTests
//
//  Tests for Level 2 phase transitions.
//

import XCTest
@testable import Cheese_Heist

final class Level2PhaseMachineTests: XCTestCase {

    func testInitialTransition() {
        XCTAssertEqual(
            Level2PhaseMachine.next(from: .aligningCrane, on: .detectionViable),
            .detectingGears
        )
    }

    func testDetectionToRolesSelection() {
        let pair = GearPair(driver: .eightTooth, follower: .fortyTooth)
        let assignment = GearRoleAssignment(driverID: UUID(), followerID: UUID())

        XCTAssertEqual(
            Level2PhaseMachine.next(from: .detectingGears, on: .detectionLocked(pair, assignment)),
            .selectingRoles
        )
    }

    func testRolesChosenToCrankingOnJoystick() {
        XCTAssertEqual(
            Level2PhaseMachine.next(from: .rolesChosen, on: .joystickEngaged),
            .cranking
        )
    }

    func testCrankingSuccess() {
        XCTAssertEqual(
            Level2PhaseMachine.next(from: .cranking, on: .liftReachedCeiling),
            .succeeded
        )
    }

    func testCrankingStallToShakingToFailedWeak() {
        XCTAssertEqual(
            Level2PhaseMachine.next(from: .cranking, on: .stallDetected),
            .stallShaking
        )
        XCTAssertEqual(
            Level2PhaseMachine.next(from: .stallShaking, on: .shakeCompleted),
            .failedWeak
        )
    }

    func testCrankingTimerExpiredToFailedSlow() {
        XCTAssertEqual(
            Level2PhaseMachine.next(from: .cranking, on: .timerExpired),
            .failedSlow
        )
    }

    func testRetryResetsToAligningCrane() {
        XCTAssertEqual(
            Level2PhaseMachine.next(from: .failedWeak, on: .tappedRetry),
            .aligningCrane
        )
        XCTAssertEqual(
            Level2PhaseMachine.next(from: .succeeded, on: .tappedRetry),
            .aligningCrane
        )
    }

    func testRestartFromAnyPhase() {
        XCTAssertEqual(
            Level2PhaseMachine.next(from: .cranking, on: .tappedRestart),
            .aligningCrane
        )
        XCTAssertEqual(
            Level2PhaseMachine.next(from: .failedWeak, on: .tappedRestart),
            .aligningCrane
        )
    }
}
