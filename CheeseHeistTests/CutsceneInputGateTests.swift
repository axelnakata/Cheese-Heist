//
//  CutsceneInputGateTests.swift
//  CheeseHeistTests
//
//  Verifies the input gate for each cutscene phase.
//

import Testing
@testable import Cheese_Heist

struct CutsceneInputGateTests {

    @Test("scanning with valid surface — surface tappable, nothing else")
    func scanningValid() {
        let gate = CutsceneInputGate.of(.scanning, isSurfaceValid: true)
        #expect(gate.surfaceTappable == true)
        #expect(gate.tapAdvances == false)
        #expect(gate.blueprintTappable == false)
    }

    @Test("scanning with invalid surface — nothing tappable")
    func scanningInvalid() {
        let gate = CutsceneInputGate.of(.scanning, isSurfaceValid: false)
        #expect(gate.surfaceTappable == false)
        #expect(gate.tapAdvances == false)
        #expect(gate.blueprintTappable == false)
    }

    @Test("introducing — tap advances, nothing else")
    func introducing() {
        let gate = CutsceneInputGate.of(.introducing)
        #expect(gate.surfaceTappable == false)
        #expect(gate.tapAdvances == true)
        #expect(gate.blueprintTappable == false)
    }

    @Test("narrating non-last beat — tap advances only")
    func narratingEarly() {
        let gate = CutsceneInputGate.of(.narrating(0))
        #expect(gate.surfaceTappable == false)
        #expect(gate.tapAdvances == true)
        #expect(gate.blueprintTappable == false)
    }

    @Test("narrating last beat — blueprint only")
    func narratingLast() {
        let last = CutsceneScript.beats.count - 1
        let gate = CutsceneInputGate.of(.narrating(last))
        #expect(gate.surfaceTappable == false)
        #expect(gate.tapAdvances == false)
        #expect(gate.blueprintTappable == true)
    }

    @Test("handingOff — nothing")
    func handingOff() {
        let gate = CutsceneInputGate.of(.handingOff)
        #expect(gate == CutsceneInputGate.none)
    }
}
