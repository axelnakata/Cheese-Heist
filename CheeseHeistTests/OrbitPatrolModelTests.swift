//
//  OrbitPatrolModelTests.swift
//  CheeseHeistTests
//
//  Angular velocity, wrapping, pause cadence, and the never-idle-over-1.5s invariant.
//

import Testing
@testable import Cheese_Heist

struct OrbitPatrolModelTests {

    @Test("angular velocity matches speed / radius")
    func angularVelocity() {
        let radius = 0.18
        let speed = 0.04
        var model = OrbitPatrolModel(radius: radius, speed: speed, seed: 42)

        // Advance by a small time where no pause should occur.
        let state = model.advance(by: 0.1)
        let expectedAngle = (speed / radius) * 0.1
        #expect(abs(state.angle - expectedAngle) < 0.001)
    }

    @Test("angle wraps to [0, 2π)")
    func angleWraps() {
        var model = OrbitPatrolModel(radius: 0.18, speed: 0.18, seed: 0)

        // Advance enough for several full revolutions.
        let state = model.advance(by: 100)
        #expect(state.angle >= 0)
        #expect(state.angle < .pi * 2)
    }

    @Test("zero delta time produces no change")
    func zeroDeltaTime() {
        var model = OrbitPatrolModel(radius: 0.18, speed: 0.04, seed: 0)
        let state = model.advance(by: 0)
        #expect(state.angle == 0)
        #expect(state.isPaused == false)
    }

    @Test("never idle for more than 1.5 seconds")
    func neverIdleTooLong() {
        var model = OrbitPatrolModel(radius: 0.18, speed: 0.04, seed: 123)

        var lastMovingAngle: Double = 0
        var pauseStart: Double?
        var maxPause: Double = 0

        let steps = 10_000
        let deltaTime = 0.016 // ~60 Hz
        var time: Double = 0

        for _ in 0..<steps {
            let state = model.advance(by: deltaTime)
            time += deltaTime

            if state.isPaused {
                if pauseStart == nil {
                    pauseStart = time
                    lastMovingAngle = state.angle
                }
            } else {
                if let start = pauseStart {
                    let pauseLength = time - start
                    maxPause = max(maxPause, pauseLength)
                    pauseStart = nil
                }
            }
        }

        // If still paused at the end.
        if let start = pauseStart {
            maxPause = max(maxPause, time - start)
        }

        // The pause duration is random in [0.5, 1.5], so the maximum observed should
        // be ≤ 1.5 plus one frame of simulation error.
        #expect(maxPause < 1.6, "cat was idle for \(maxPause)s, exceeding the 1.5s limit")
    }

    @Test("pause cadence occurs within expected range")
    func pauseOccursWithinRange() {
        var model = OrbitPatrolModel(radius: 0.18, speed: 0.04, seed: 99)

        var hasPaused = false
        let deltaTime = 0.016

        // Run for 10 seconds — should hit at least one pause.
        for _ in 0..<625 {
            let state = model.advance(by: deltaTime)
            if state.isPaused { hasPaused = true }
        }

        #expect(hasPaused, "cat never paused in 10 seconds of simulation")
    }
}
