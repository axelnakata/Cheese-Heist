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

    /// The alignment illustration comes down when the DETECTOR is ready, not when the
    /// child taps — tapping past it would leave them detecting from a viewpoint the
    /// model cannot work with.
    @Test("alignment and detection accept no input at all")
    func earlyPhasesAreInert() {
        for phase in [Level1Phase.aligningCrane, .detectingGears, .manualFallback] {
            #expect(Level1InputGate.of(phase) == .none, "\(phase)")
        }
    }

    /// Gears stay pickable from the first tap right through `rolesChosen` — the choice
    /// is only locked in by the first turn of the joystick, not by a separate commit.
    @Test("gears are tappable in selectingRoles and rolesChosen only")
    func gearsTappableWindow() {
        let tappable: Set<Level1Phase> = [.selectingRoles, .rolesChosen]
        for phase in Level1Phase.allCases {
            #expect(
                Level1InputGate.of(phase).gearsTappable == tappable.contains(phase),
                "\(phase)"
            )
        }
    }

    @Test("the joystick is live exactly in the phases that lift, plus rolesChosen")
    func joystickMatchesLiftSegments() {
        for phase in Level1Phase.allCases {
            let expected = phase.liftSegment != nil || phase == .rolesChosen
            #expect(Level1InputGate.of(phase).joystickEnabled == expected, "\(phase)")
        }
    }

    /// The success overlay owns its own buttons.
    @Test("succeeded accepts no input")
    func succeededIsInert() {
        #expect(Level1InputGate.of(.succeeded) == .none)
    }
}
