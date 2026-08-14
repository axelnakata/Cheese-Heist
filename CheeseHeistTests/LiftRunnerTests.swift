//
//  LiftRunnerTests.swift
//  CheeseHeistTests
//
//  The two ways the lift misreported itself on device.
//
//  1. It finished early. The ceiling was `tuning.liftHeight`, a flat 6cm, while the rope
//     is as long as the crane the child built — so on a taller crane "CHEESE SECURED!"
//     appeared with the cheese still swinging in mid-air and rope left above it.
//  2. It ran with nobody cranking. A finger resting on the joystick sends no drag
//     events, and the engagement was only ever recomputed by a drag event, so it stayed
//     `.engaged` and the gears turned on their own.
//
//  Both are testable without a device: `LiftRunner` talks to the scene through
//  `CraneSceneProviding`, and `MockCraneScene` is one.
//

import Foundation
import Testing
@testable import Cheese_Heist

@MainActor
struct LiftRunnerTests {

    private static let pair = GearPair(driver: .eightTooth, follower: .fortyTooth)

    /// A crane whose cheese has this far to travel — deliberately DIFFERENT from
    /// `Level1Tuning.value.liftHeight`, so a runner still using the tuning constant
    /// fails rather than coincidentally passing.
    private static let travel: Float = 0.13

    /// `LiftRunner` holds its scene WEAKLY — in the app the coordinator is owned by
    /// `AppServices`. A test that lets the mock go out of scope silently gets a runner
    /// with no scene to measure, which is a green test for a broken reason.
    private struct Rig {
        let runner: LiftRunner
        let scene: MockCraneScene
    }

    private static func rig(travel: Float = travel) -> Rig {
        let scene = MockCraneScene()
        scene.maximumLift = travel
        let runner = LiftRunner(
            tuning: Level1Tuning.value, scene: scene,
            durationProvider: { Level1LiftDurations.duration(for: $0) }
        )
        runner.setPair(pair)
        return Rig(runner: runner, scene: scene)
    }

    /// Cranks for `seconds` of simulated time at 60fps.
    private static func crank(_ runner: LiftRunner, for seconds: Double) {
        let step = 1.0 / 60
        for _ in 0..<Int(seconds / step) { runner.advance(deltaTime: step) }
    }

    @Test("the lift ends where the rope does, not at the tuning constant")
    func ceilingIsTheMeasuredTravel() {
        let rig = Self.rig()
        let runner = rig.runner
        var reachedCeiling = false
        runner.onReachedCeiling = { reachedCeiling = true }

        runner.continueInto(.full)
        runner.isCranking = true
        Self.crank(runner, for: 20)

        #expect(reachedCeiling)
        #expect(abs(runner.state.height - Double(Self.travel)) < 0.0005)
    }

    /// Otherwise the guided run's first half stops in a different place on every crane.
    @Test("the halfway beat stops halfway up the measured travel")
    func halfSegmentIsHalfTheMeasuredTravel() {
        let rig = Self.rig()
        let runner = rig.runner
        runner.continueInto(.half)
        runner.isCranking = true
        Self.crank(runner, for: 20)

        #expect(abs(runner.state.height - Double(Self.travel) / 2) < 0.0005)
    }

    @Test("progress is measured against the same travel")
    func progressFillsExactlyOnceAtTheTop() {
        let rig = Self.rig()
        let runner = rig.runner
        runner.continueInto(.full)
        runner.isCranking = true
        Self.crank(runner, for: 20)

        #expect(abs(runner.progress - 1) < 0.001)
    }

    @Test("nothing turns and nothing rises while the crank is idle")
    func idleCrankMovesNothing() {
        let rig = Self.rig()
        let runner = rig.runner
        let scene = rig.scene
        runner.continueInto(.full)
        runner.isCranking = false
        Self.crank(runner, for: 5)

        #expect(runner.state.height == 0)
        #expect(runner.state.driverAngle == 0)
        #expect(scene.lastState.driverAngle == 0)
    }

    /// Stopping mid-lift holds the cheese where it is — the crane has a ratchet, and
    /// letting go must not drop the load.
    @Test("releasing the crank holds the height")
    func releasingHoldsHeight() {
        let rig = Self.rig()
        let runner = rig.runner
        runner.continueInto(.full)
        runner.isCranking = true
        Self.crank(runner, for: 0.5)

        let reached = runner.state.height
        #expect(reached > 0)

        runner.isCranking = false
        Self.crank(runner, for: 5)
        #expect(runner.state.height == reached)
    }

    /// A crane so short that the cheese already touches its follower gear still has to
    /// be finishable.
    @Test("a crane with no room left still has a lift to run")
    func degenerateTravelStillFinishes() {
        let rig = Self.rig(travel: 0)
        let runner = rig.runner
        runner.continueInto(.full)
        runner.isCranking = true
        Self.crank(runner, for: 20)

        #expect(runner.state.height > 0)
    }

    /// The whole point of the designed-duration model: a taller crane and a shorter
    /// crane, same gear pair, both finish in the same number of simulated ticks — only
    /// the rope speed differs, never the total time.
    @Test("two different crane heights with the same pair finish in the same number of ticks")
    func sameDurationRegardlessOfHeight() {
        func ticksToCeiling(travel: Float) -> Int {
            let rig = Self.rig(travel: travel)
            let runner = rig.runner
            runner.continueInto(.full)
            runner.isCranking = true

            let step = 1.0 / 60
            for tick in 0..<6_000 {
                runner.advance(deltaTime: step)
                if runner.progress >= 1 { return tick + 1 }
            }
            return .max
        }

        let short = ticksToCeiling(travel: 0.05)
        let tall = ticksToCeiling(travel: 0.25)

        #expect(short == tall)
    }
}
