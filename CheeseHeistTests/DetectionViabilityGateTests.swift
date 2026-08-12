//
//  DetectionViabilityGateTests.swift
//  CheeseHeistTests
//
//  The replacement for the parent PRD §11.5.1 reticle: the alignment illustration comes
//  down when the model can actually see gears, not when a proxy for that is satisfied.
//

import Testing
@testable import Cheese_Heist

struct DetectionViabilityGateTests {

    @Test("two consecutive frames with a gear pass the gate")
    func passesAfterTwo() {
        var gate = DetectionViabilityGate()

        #expect(gate.observe(gearCount: 1) == false)
        #expect(gate.observe(gearCount: 1) == true)
        #expect(gate.isViable)
    }

    /// One lucky frame is not evidence that the crane is framed.
    @Test("an empty frame clears the streak")
    func emptyFrameResets() {
        var gate = DetectionViabilityGate()

        gate.observe(gearCount: 2)
        gate.observe(gearCount: 0)
        #expect(!gate.isViable)

        gate.observe(gearCount: 2)
        #expect(!gate.isViable)
        gate.observe(gearCount: 2)
        #expect(gate.isViable)
    }

    /// The caller fires its event on the true, so it must be true exactly once.
    @Test("the gate reports passing only on the frame it passes")
    func firesOnce() {
        var gate = DetectionViabilityGate()
        gate.observe(gearCount: 1)

        #expect(gate.observe(gearCount: 1) == true)
        #expect(gate.observe(gearCount: 1) == false)
        #expect(gate.observe(gearCount: 0) == false)
    }

    @Test("reset re-arms the gate for a retry")
    func resetRearms() {
        var gate = DetectionViabilityGate()
        gate.observe(gearCount: 1)
        gate.observe(gearCount: 1)

        gate.reset()
        #expect(!gate.isViable)
        #expect(gate.observe(gearCount: 1) == false)
    }
}
