//
//  TimerBadgeTests.swift
//  CheeseHeistTests
//
//  Idle stays neutral; running tracks the star zone it's warning about.
//

import Testing
import SwiftUI
@testable import Cheese_Heist

struct TimerBadgeTests {

    @Test("idle is always neutral, regardless of seconds")
    func idleIsNeutral() {
        #expect(TimerBadge.fill(seconds: 15, isRunning: false) == AppColor.surfaceInstruction)
        #expect(TimerBadge.fill(seconds: 0, isRunning: false) == AppColor.surfaceInstruction)
    }

    @Test("10 or more seconds remaining is green — 3★ still reachable")
    func greenZone() {
        #expect(TimerBadge.fill(seconds: 15, isRunning: true) == AppColor.stateValid)
        #expect(TimerBadge.fill(seconds: 10, isRunning: true) == AppColor.stateValid)
    }

    @Test("5 to 9 seconds remaining is caution — 2★ zone")
    func cautionZone() {
        #expect(TimerBadge.fill(seconds: 9, isRunning: true) == AppColor.stateCaution)
        #expect(TimerBadge.fill(seconds: 5, isRunning: true) == AppColor.stateCaution)
    }

    @Test("under 5 seconds remaining is invalid — 1★ zone, about to fail-slow")
    func invalidZone() {
        #expect(TimerBadge.fill(seconds: 4, isRunning: true) == AppColor.stateInvalid)
        #expect(TimerBadge.fill(seconds: 0, isRunning: true) == AppColor.stateInvalid)
    }
}
