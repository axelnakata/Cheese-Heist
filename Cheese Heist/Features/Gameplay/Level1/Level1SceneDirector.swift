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
    func stage(_ phase: Level1Phase, assignment: GearRoleAssignment?) {
        scene.setMousePose(mousePose(for: phase))
        scene.setRopeVisible(true)
        scene.setHighlightedGears(highlighted(for: phase, assignment: assignment))
    }

    /// Which pose the mouse wears.
    ///
    /// It struggles only where the lesson is about the load — mid-lift, when the
    /// follower is being named — and is delighted at the top. A mouse that looks the
    /// same throughout is a mouse the child stops looking at.
    func mousePose(for phase: Level1Phase) -> MouseSprite {
        switch phase {
        case .guidedCrankToHalf, .teachingFollower, .guidedCrankToFull, .freeCrank:
            return .talkStruggle
        case .handOver, .selectingRoles, .succeeded:
            return .shockHappy
        default:
            return .talkIdle
        }
    }

    /// Which gears pulse.
    ///
    /// Both of them during role selection — the child is being asked to choose, so both
    /// have to read as choosable. Just the one being talked about while teaching.
    func highlighted(
        for phase: Level1Phase, assignment: GearRoleAssignment?
    ) -> Set<UUID> {
        guard let assignment else { return [] }

        switch phase {
        case .teachingDriver:
            return [assignment.driverID]
        case .teachingFollower:
            return [assignment.followerID]
        case .selectingRoles:
            return [assignment.driverID, assignment.followerID]
        default:
            return []
        }
    }

    /// Where the teaching spotlight is cut, if anywhere.
    func spotlight(for phase: Level1Phase) -> SpotlightSubject {
        switch phase {
        case .teachingDriver:    return .driverGear
        case .teachingJoystick:  return .joystick
        case .teachingFollower:  return .followerGearAndRope
        default:                 return .none
        }
    }

    /// Level 1's teaching run starts on the SMALL gear as driver.
    ///
    /// A deliberate choice, not an arbitrary one: the small gear as driver is the
    /// gearing-up case, so the guided run the child watches first is the SLOW one. When
    /// they then choose for themselves and pick the other way round, the difference is
    /// something they have already seen the baseline for.
    static func initialAssignment(for gears: [DetectedGear]) -> GearRoleAssignment? {
        guard gears.count == 2 else { return nil }
        let ordered = GearOrdering.ordered(gears)
        return GearRoleAssignment(driverID: ordered[0].id, followerID: ordered[1].id)
    }

    /// The gear pair the physics runs on, read ONCE at lock.
    static func pair(for gears: [DetectedGear], assignment: GearRoleAssignment) -> GearPair? {
        guard let driver = gears.first(where: { $0.id == assignment.driverID }),
              let follower = gears.first(where: { $0.id == assignment.followerID })
        else { return nil }
        return GearPair(driver: driver.type, follower: follower.type)
    }
}
