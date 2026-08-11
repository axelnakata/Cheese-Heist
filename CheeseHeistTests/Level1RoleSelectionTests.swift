//
//  Level1RoleSelectionTests.swift
//  CheeseHeistTests
//
//  "It's your turn — tap a gear to make it the driver" has to actually stick.
//
//  ═══ THE BUG THIS PINS DOWN ═══
//
//  `Level1ViewModel.handle(_:)` applied an event's PAYLOAD before asking the phase
//  machine whether the event was accepted at all. `observeDetection()` republishes
//  `.detectionLocked` on every tracking update — several times a second, for the whole
//  level — and each one carries `initialAssignment`, which is always the LEFT gear as
//  driver. So the child tapped the 40T, the mouse set off toward it, and a fifth of a
//  second later the roles were back the way they started. On device it read as "the
//  driver is always the left gear and the labels never change".
//
//  The machine rejects `.detectionLocked` in every phase after the lock. Consulting it
//  first is the whole fix, and this is the test that says so.
//

import Foundation
import Testing
@testable import Cheese_Heist

@MainActor
struct Level1RoleSelectionTests {

    private struct Flow {
        let viewModel: Level1ViewModel
        let scene: MockCraneScene
        let initial: GearRoleAssignment
        var leftGear: UUID { initial.driverID }
        var rightGear: UUID { initial.followerID }
    }

    /// Walks the flow to `selectingRoles` through the machine, so the phases and their
    /// entry effects are the real ones.
    private static func atRoleSelection() -> Flow {
        let scene = MockCraneScene()
        let viewModel = Level1ViewModel(detection: GearDetectionService())
        viewModel.attach(scene: scene)

        let assignment = GearRoleAssignment(
            driverID: scene.placements[0].id, followerID: scene.placements[1].id
        )
        let pair = GearPair(
            driver: scene.placements[0].type, follower: scene.placements[1].type
        )

        viewModel.handle(.detectionLocked(pair: pair, assignment: assignment))
        for event: Level1Event in [
            .tappedContinue, .tappedContinue, .tappedContinue,
            .liftReachedCeiling, .tappedContinue, .liftReachedCeiling, .tappedContinue
        ] {
            viewModel.handle(event)
        }

        return Flow(viewModel: viewModel, scene: scene, initial: assignment)
    }

    /// Which gear the SCENE thinks is the driver — the same value the role labels and
    /// the mouse's perch are read off, rather than the ViewModel's own copy.
    private static func sceneDriver(_ flow: Flow) -> UUID? {
        flow.scene.screenTargets.first { $0.role == .driver }?.id
    }

    @Test("the walk reaches role selection")
    func reachesRoleSelection() {
        #expect(Self.atRoleSelection().viewModel.phase == .selectingRoles)
    }

    @Test("tapping the other gear makes it the driver")
    func tapAssignsDriver() {
        let flow = Self.atRoleSelection()
        flow.viewModel.handle(.tappedGear(id: flow.rightGear))

        #expect(flow.viewModel.selection.assignment?.driverID == flow.rightGear)
        #expect(Self.sceneDriver(flow) == flow.rightGear)
    }

    /// The regression. A detector republish arriving while the child is choosing must
    /// not put the roles back.
    @Test("a detector republish does not undo the child's choice")
    func republishedLockDoesNotResetRoles() {
        let flow = Self.atRoleSelection()
        flow.viewModel.handle(.tappedGear(id: flow.rightGear))

        let pair = GearPair(
            driver: flow.scene.placements[0].type, follower: flow.scene.placements[1].type
        )
        for _ in 0..<10 {
            flow.viewModel.handle(.detectionLocked(pair: pair, assignment: flow.initial))
        }

        #expect(flow.viewModel.phase == .selectingRoles)
        #expect(flow.viewModel.selection.assignment?.driverID == flow.rightGear)
        #expect(Self.sceneDriver(flow) == flow.rightGear)
    }

    /// …and it must not silently unlock a committed choice either: `selection.begin`
    /// clears the PULL lock, so the same republish also handed the gears back after the
    /// child had committed and started cranking.
    @Test("a detector republish does not unlock a committed choice")
    func republishedLockDoesNotUnlockSelection() {
        let flow = Self.atRoleSelection()
        flow.viewModel.handle(.tappedGear(id: flow.rightGear))
        flow.viewModel.handle(.tappedPull)

        let pair = GearPair(
            driver: flow.scene.placements[0].type, follower: flow.scene.placements[1].type
        )
        flow.viewModel.handle(.detectionLocked(pair: pair, assignment: flow.initial))

        #expect(flow.viewModel.phase == .freeCrank)
        #expect(flow.viewModel.selection.isLocked)
        #expect(flow.viewModel.selection.assignment?.driverID == flow.rightGear)
    }

    /// Tapping the gear that is ALREADY the driver changes nothing and breaks nothing.
    @Test("re-tapping the driver is a no-op")
    func retappingDriverIsHarmless() {
        let flow = Self.atRoleSelection()
        flow.viewModel.handle(.tappedGear(id: flow.leftGear))

        #expect(flow.viewModel.selection.assignment?.driverID == flow.leftGear)
        #expect(Self.sceneDriver(flow) == flow.leftGear)
    }
}
