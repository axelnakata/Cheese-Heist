// Level2SceneDirector.swift — Cheese Heist
// PRD-Level2 §6 — what the scene should look like in each phase.
//
// Level 2 has no tutorial choreography — no spotlight, no stepping through half-lifts.
// The mouse wears `happy` during play and there is no teaching sequence. What IS new:
//   • The same `initialAssignment` and `pair(for:)` helpers as Level 1.
//   • No spotlight at all — the child already learned in Level 1.

import Foundation

@MainActor
struct Level2SceneDirector {

    private let scene: any CraneSceneProviding

    init(scene: any CraneSceneProviding) {
        self.scene = scene
    }

    /// Everything the scene should look like in this phase, applied at once.
    func stage(_ phase: Level2Phase) {
        scene.setMousePose(mousePose(for: phase))
        scene.setRopeVisible(true)
    }

    /// Which pose the mouse wears.
    func mousePose(for phase: Level2Phase) -> MouseSprite {
        switch phase {
        case .stallShaking: return .talkStruggle
        default: return .happy
        }
    }

    /// The success micro-interaction: a small particle burst over the gears. No fail
    /// counterpart — a stall or a timeout is carried by the fail SFX and the result
    /// overlay alone.
    func celebrate(starCount: Int) {
        scene.playCelebration(starCount: starCount)
    }

    // MARK: - Assignment helpers (same as Level 1)

    /// Level 2 also starts on the left gear as driver — a convention, not a teaching
    /// requirement. The child is free to change it immediately.
    static func initialAssignment(leftToRight gears: [DetectedGear]) -> GearRoleAssignment? {
        guard gears.count == 2 else { return nil }
        return GearRoleAssignment(driverID: gears[0].id, followerID: gears[1].id)
    }

    /// The gear pair the physics runs on, derived from the assignment.
    static func pair(for gears: [DetectedGear], assignment: GearRoleAssignment) -> GearPair? {
        guard let driver = gears.first(where: { $0.id == assignment.driverID }),
              let follower = gears.first(where: { $0.id == assignment.followerID })
        else { return nil }
        return GearPair(driver: driver.type, follower: follower.type)
    }
}
