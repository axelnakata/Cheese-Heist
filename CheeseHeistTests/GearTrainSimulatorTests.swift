//
//  GearTrainSimulatorTests.swift
//  CheeseHeistTests
//
//  PRD §12.1 — `LiftSegment.half` stops at exactly 50%, the follower's angle is derived
//  rather than integrated, and no crank means no movement.
//

import Testing
@testable import Cheese_Heist

struct GearTrainSimulatorTests {

    let tuning = Level1Tuning.value
    let pair = GearPair(driver: .eightTooth, follower: .fortyTooth)

    /// Runs until the ceiling is reported, or gives up. Returns the state and how long
    /// the lift took in simulated seconds.
    private func run(
        segment: LiftSegment, from state: GearTrainState = GearTrainState()
    ) -> (state: GearTrainState, seconds: Double) {
        var state = state
        state.isCranking = true
        let step = 1.0 / 60

        for tick in 0..<6_000 {
            let outcome = GearTrainSimulator.advance(
                state: &state, pair: pair, tuning: tuning, segment: segment, deltaTime: step
            )
            if outcome == .reachedCeiling { return (state, Double(tick + 1) * step) }
        }
        return (state, .infinity)
    }

    @Test("the guided run stops at exactly half the lift height")
    func halfSegmentStopsAtFiftyPercent() {
        let result = run(segment: .half)
        #expect(abs(result.state.height - tuning.liftHeight / 2) < 1e-9)
    }

    /// The free run is the identical code path, differing only in the Double it was
    /// handed — so continuing from the half point must reach the top.
    @Test("continuing into the full segment reaches the top")
    func fullSegmentCompletesTheLift() {
        let half = run(segment: .half)
        let full = run(segment: .full, from: half.state)

        #expect(abs(full.state.height - tuning.liftHeight) < 1e-9)
    }

    /// Independent integration accumulates float drift and the teeth visibly unmesh.
    @Test("the follower's angle is derived from the driver's, exactly")
    func followerAngleIsDerived() {
        let result = run(segment: .full)
        let expected = -result.state.driverAngle / pair.ratio

        #expect(result.state.followerAngle(ratio: pair.ratio) == expected)
    }

    /// A ratchet: letting go holds the cheese where it is rather than dropping it.
    @Test("no crank means no movement")
    func ratchetHoldsHeight() {
        var state = GearTrainState()
        state.height = 0.03
        state.isCranking = false

        let outcome = GearTrainSimulator.advance(
            state: &state, pair: pair, tuning: tuning, segment: .full, deltaTime: 1.0 / 60
        )

        #expect(outcome == nil)
        #expect(state.height == 0.03)
    }

    @Test("reset returns the train to the table")
    func resetClearsState() {
        var state = GearTrainState(driverAngle: 12, height: 0.05, isCranking: true)
        GearTrainSimulator.reset(state: &state)

        #expect(state == GearTrainState())
    }

    /// The `i²` spread between the child's two role choices is the point of the free
    /// run — gearing up is slow, gearing down is fast.
    @Test("swapping the roles changes how long the lift takes")
    func roleChoiceChangesLiftTime() {
        var gearedUp = GearTrainState()
        gearedUp.isCranking = true
        var gearedDown = gearedUp

        let step = 1.0 / 60
        for _ in 0..<60 {
            _ = GearTrainSimulator.advance(
                state: &gearedUp, pair: pair, tuning: tuning, segment: .full, deltaTime: step
            )
            _ = GearTrainSimulator.advance(
                state: &gearedDown, pair: pair.swapped, tuning: tuning,
                segment: .full, deltaTime: step
            )
        }

        #expect(gearedDown.height > gearedUp.height)
    }
}
