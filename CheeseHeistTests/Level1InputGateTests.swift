//
//  Level1InputGateTests.swift
//  CheeseHeistTests
//
//  The gate is what stops the phase switch being repeated in three views, so its
//  invariants are worth pinning down.
//

import Testing
@testable import Cheese_Heist

struct Level1InputGateTests {

    /// D-2: PULL commits, the joystick cranks. They occupy the same corner and must
    /// never be on screen together.
    @Test("PULL and the joystick are never both live")
    func pullAndJoystickAreExclusive() {
        for phase in Level1Phase.allCases {
            let gate = Level1InputGate.of(phase)
            #expect(!(gate.pullVisible && gate.joystickEnabled), "\(phase)")
        }
    }

    /// While PULL is visible the child may keep re-tapping gears to swap roles; once it
    /// is gone the assignment is locked.
    @Test("gears are tappable exactly while PULL is visible")
    func gearsFollowPull() {
        for phase in Level1Phase.allCases {
            let gate = Level1InputGate.of(phase)
            #expect(gate.gearsTappable == gate.pullVisible, "\(phase)")
        }
    }

    /// The alignment illustration comes down when the DETECTOR is ready, not when the
    /// child taps — tapping past it would leave them detecting from a viewpoint the
    /// model cannot work with.
    @Test("alignment and detection accept no input at all")
    func earlyPhasesAreInert() {
        for phase in [Level1Phase.aligningCrane, .detectingGears, .manualFallback] {
            #expect(Level1InputGate.of(phase) == .none, "\(phase)")
        }
    }

    /// A tap must not both advance a beat and drive the crank.
    @Test("tap-to-advance and cranking are mutually exclusive")
    func tapAndCrankAreExclusive() {
        for phase in Level1Phase.allCases {
            let gate = Level1InputGate.of(phase)
            #expect(!(gate.tapAdvances && gate.joystickEnabled), "\(phase)")
        }
    }

    @Test("the joystick is live exactly in the phases that lift")
    func joystickMatchesLiftSegments() {
        for phase in Level1Phase.allCases {
            #expect(
                Level1InputGate.of(phase).joystickEnabled == (phase.liftSegment != nil),
                "\(phase)"
            )
        }
    }
}
