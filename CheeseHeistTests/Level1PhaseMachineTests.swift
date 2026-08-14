//
//  Level1PhaseMachineTests.swift
//  CheeseHeistTests
//
//  PRD §12.1 — every `Level1Phase` × `Level1Event` pair produces the transition table's
//  result.
//
//  The whole flow is verifiable here before a single pixel exists, which is why the
//  machine was written pure and total in the first place.
//

import Foundation
import Testing
@testable import Cheese_Heist

struct Level1PhaseMachineTests {

    static let pair = GearPair(driver: .eightTooth, follower: .fortyTooth)
    static let assignment = GearRoleAssignment(driverID: UUID(), followerID: UUID())

    /// The transition table, transcribed. Anything not listed here must return nil.
    static let table: [(Level1Phase, Level1Event, Level1Phase)] = [
        (.aligningCrane, .detectionViable, .detectingGears),
        // The detector can reach viability and a lock on the same tick, and nothing
        // orders the two signals — so the illustration must accept a lock directly.
        (.aligningCrane, .detectionLocked(pair: pair, assignment: assignment), .selectingRoles),
        (.aligningCrane, .detectionTimedOut, .manualFallback),
        (.detectingGears, .detectionLocked(pair: pair, assignment: assignment), .selectingRoles),
        (.detectingGears, .detectionTimedOut, .manualFallback),
        (.manualFallback, .detectionLocked(pair: pair, assignment: assignment), .selectingRoles),
        (.selectingRoles, .tappedGear(id: assignment.driverID), .rolesChosen),
        (.rolesChosen, .tappedGear(id: assignment.driverID), .rolesChosen),
        (.rolesChosen, .joystickEngaged, .freeCrank),
        (.freeCrank, .liftReachedCeiling, .succeeded),
        (.succeeded, .tappedRetry, .aligningCrane)
    ]

    static let allEvents: [Level1Event] = [
        .detectionViable,
        .detectionLocked(pair: pair, assignment: assignment),
        .detectionTimedOut,
        .liftReachedCeiling,
        .tappedGear(id: assignment.driverID),
        .joystickEngaged,
        .tappedRetry,
        .tappedNext,
        .trackingLost,
        .trackingRegained
    ]

    @Test("every listed transition produces the table's result")
    func tableIsHonoured() {
        for (phase, event, expected) in Self.table {
            #expect(
                Level1PhaseMachine.next(from: phase, on: event) == expected,
                "\(phase) on \(event)"
            )
        }
    }

    /// Total, not partial: nil is a legitimate answer meaning "ignore this event here".
    @Test("everything not in the table is ignored")
    func unlistedPairsAreIgnored() {
        let listed = Set(Self.table.map { "\($0.0)|\($0.1)" })

        for phase in Level1Phase.allCases {
            for event in Self.allEvents where !listed.contains("\(phase)|\(event)") {
                #expect(
                    Level1PhaseMachine.next(from: phase, on: event) == nil,
                    "\(phase) on \(event) should be ignored"
                )
            }
        }
    }

    /// Tracking is a HUD note. Losing the gears behind a hand must not knock the child
    /// out of a lesson — the anchor is still holding the scene exactly where it was.
    @Test("tracking events never change the phase")
    func trackingNeverTransitions() {
        for phase in Level1Phase.allCases {
            #expect(Level1PhaseMachine.next(from: phase, on: .trackingLost) == nil)
            #expect(Level1PhaseMachine.next(from: phase, on: .trackingRegained) == nil)
        }
    }

    /// OQ-L2 — `Next` routes nowhere in this release.
    @Test("Next is a no-op")
    func nextIsNoOp() {
        #expect(Level1PhaseMachine.next(from: .succeeded, on: .tappedNext) == nil)
    }

    /// Retry returns to the ILLUSTRATION, not to role selection: the child may have put
    /// the iPad down, and the crane has to be found again.
    @Test("retry returns to alignment")
    func retryReturnsToAlignment() {
        #expect(Level1PhaseMachine.next(from: .succeeded, on: .tappedRetry) == .aligningCrane)
    }

    /// Walking the table from the start must reach `succeeded` — proof the flow has no
    /// gap in it.
    @Test("the happy path runs end to end")
    func happyPathCompletes() {
        let script: [Level1Event] = [
            .detectionViable,
            .detectionLocked(pair: Self.pair, assignment: Self.assignment),
            .tappedGear(id: Self.assignment.driverID),
            .joystickEngaged,
            .liftReachedCeiling
        ]

        var phase = Level1Phase.aligningCrane
        for event in script {
            guard let next = Level1PhaseMachine.next(from: phase, on: event) else {
                Issue.record("\(phase) refused \(event)")
                return
            }
            phase = next
        }

        #expect(phase == .succeeded)
    }

    @Test("only freeCrank lifts")
    func liftSegments() {
        #expect(Level1Phase.freeCrank.liftSegment == .full)

        for phase in Level1Phase.allCases where phase != .freeCrank {
            #expect(phase.liftSegment == nil)
        }
    }
}
