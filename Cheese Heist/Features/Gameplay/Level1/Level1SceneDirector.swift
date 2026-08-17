//
//  Level1SceneDirector.swift
//  Cheese Heist
//
//  The teaching choreography: which pose the mouse wears, which gear glows, where the
//  spotlight is cut, whether the rope is up.
//
//  THE CHOREOGRAPHY *IS* THE LESSON, which is why this lives in `Level1/` rather than
//  in `Shared/`. Level 2 aligns a crane, detects gears, runs the same physics and draws
//  the same components — but it teaches a different thing in a different order, and the
//  mouse standing on the driver at exactly the moment the driver is named is the part
//  that does not transfer.
//
//  It draws nothing and computes nothing. It reads a phase and tells the scene.
//

import Foundation

@MainActor
struct Level1SceneDirector {

    private let scene: any CraneSceneProviding

    init(scene: any CraneSceneProviding) {
        self.scene = scene
    }

    /// Everything the scene should look like in this phase, applied at once.
    func stage(_ phase: Level1Phase) {
        scene.setMousePose(mousePose(for: phase))
        scene.setRopeVisible(true)
    }

    /// Which pose the mouse wears — `happy`, the whole way through Level 1.
    ///
    /// The other three poses exist and the phase switch that chose between them was
    /// written; it is deliberately not wired up yet. The talking art is trimmed to a
    /// different box from `happy`, so a pose change moves the mouse on its perch, and
    /// that is not worth debugging while the question on the table is whether the mouse
    /// appears at all. One sprite, one size, one thing that can be wrong.
    func mousePose(for phase: Level1Phase) -> MouseSprite {
        .happy
    }

    /// The success micro-interaction: a small particle burst over the gears. Level 1 is
    /// unfailable, so there is no `commiserate` counterpart here.
    func celebrate(starCount: Int) {
        scene.playResultEffect(.success(starCount: starCount))
    }

    /// Level 1's teaching run starts on the LEFT gear as driver.
    ///
    /// Left and right, not small and large, because this assignment is the first thing
    /// the child ever sees and it has to be legible before any of the vocabulary is:
    /// the mouse is standing on the left gear and the cheese is hanging off the right
    /// one, and nothing about that reading depends on being able to tell an 8T from a
    /// 40T at a glance. It also makes the guided run reproducible in a classroom — every
    /// iPad in the room teaches the same gear first, whichever way round the cranes were
    /// built.
    ///
    /// The gears must ALREADY be left-to-right (`GearOrdering.leftToRight`); the caller
    /// holds the crane frame that decides which is which, and this does not.
    static func initialAssignment(leftToRight gears: [DetectedGear]) -> GearRoleAssignment? {
        guard gears.count == 2 else { return nil }
        return GearRoleAssignment(driverID: gears[0].id, followerID: gears[1].id)
    }

    /// The gear pair the physics runs on, read ONCE at lock.
    static func pair(for gears: [DetectedGear], assignment: GearRoleAssignment) -> GearPair? {
        guard let driver = gears.first(where: { $0.id == assignment.driverID }),
              let follower = gears.first(where: { $0.id == assignment.followerID })
        else { return nil }
        return GearPair(driver: driver.type, follower: follower.type)
    }
}
