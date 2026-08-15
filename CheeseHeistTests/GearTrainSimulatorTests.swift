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
        state.drive = .rising
        let step = 1.0 / 60

        for tick in 0..<6_000 {
            let outcome = GearTrainSimulator.advance(
                state: &state, pair: pair, tuning: tuning, segment: segment,
                liftDuration: Level1LiftDurations.duration(for: pair), deltaTime: step
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

    /// A ratchet: holding steady holds the cheese where it is rather than dropping it.
    @Test("holding the crank steady means no movement")
    func ratchetHoldsHeight() {
        var state = GearTrainState()
        state.height = 0.03
        state.drive = .holding

        let outcome = GearTrainSimulator.advance(
            state: &state, pair: pair, tuning: tuning, segment: .full,
            liftDuration: Level1LiftDurations.duration(for: pair), deltaTime: 1.0 / 60
        )

        #expect(outcome == nil)
        #expect(state.height == 0.03)
    }

    @Test("reset returns the train to the table")
    func resetClearsState() {
        var state = GearTrainState(driverAngle: 12, height: 0.05, drive: .rising)
        GearTrainSimulator.reset(state: &state)

        #expect(state == GearTrainState())
    }

    /// Letting go or cranking backwards unwinds the rope, floored at the table — the
    /// mirror image of the rising run.
    @Test("falling unwinds the height back toward the table, never past it")
    func fallingUnwindsToTheFloor() {
        var state = GearTrainState()
        state.height = 0.03
        state.drive = .falling
        let step = 1.0 / 60

        for _ in 0..<6_000 {
            _ = GearTrainSimulator.advance(
                state: &state, pair: pair, tuning: tuning, segment: .full,
                liftDuration: Level1LiftDurations.duration(for: pair), deltaTime: step
            )
        }

        #expect(state.height == 0)
    }

    /// The driver spins backward while falling — the follower's angle is still derived
    /// from it, so the teeth stay meshed on the way down as well as the way up.
    @Test("falling turns the driver backward")
    func fallingReversesTheDriver() {
        var state = GearTrainState()
        state.height = 0.03
        state.drive = .falling

        _ = GearTrainSimulator.advance(
            state: &state, pair: pair, tuning: tuning, segment: .full,
            liftDuration: Level1LiftDurations.duration(for: pair), deltaTime: 1.0 / 60
        )

        #expect(state.driverAngle < 0)
    }

    /// A cheese already resting on the table has nothing left to unwind.
    @Test("falling at the table does nothing")
    func fallingAtTheFloorIsANoOp() {
        var state = GearTrainState()
        state.drive = .falling

        let outcome = GearTrainSimulator.advance(
            state: &state, pair: pair, tuning: tuning, segment: .full,
            liftDuration: Level1LiftDurations.duration(for: pair), deltaTime: 1.0 / 60
        )

        #expect(outcome == nil)
        #expect(state.height == 0)
        #expect(state.driverAngle == 0)
    }

    /// The `i²` spread between the child's two role choices is the point of the free
    /// run — gearing up is slow, gearing down is fast.
    @Test("swapping the roles changes how long the lift takes")
    func roleChoiceChangesLiftTime() {
        var gearedUp = GearTrainState()
        gearedUp.drive = .rising
        var gearedDown = gearedUp

        let step = 1.0 / 60
        for _ in 0..<60 {
            _ = GearTrainSimulator.advance(
                state: &gearedUp, pair: pair, tuning: tuning, segment: .full,
                liftDuration: Level1LiftDurations.duration(for: pair), deltaTime: step
            )
            _ = GearTrainSimulator.advance(
                state: &gearedDown, pair: pair.swapped, tuning: tuning, segment: .full,
                liftDuration: Level1LiftDurations.duration(for: pair.swapped), deltaTime: step
            )
        }

        #expect(gearedDown.height > gearedUp.height)
    }
}
