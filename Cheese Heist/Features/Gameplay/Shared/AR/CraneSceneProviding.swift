//
//  CraneSceneProviding.swift
//  Cheese Heist
//
//  What a Level's ViewModel is allowed to ask of the AR scene.
//
//  Every method takes and returns values that carry no ARKit or RealityKit type, which
//  is what lets `Level1ViewModel` obey PRD-Level1 §6.3 — and what lets a preview stand
//  a `MockCraneScene` in the coordinator's place and render every layer on a Mac with
//  no device attached (PRD §8.6).
//

import CoreGraphics
import Foundation

@MainActor
protocol CraneSceneProviding: AnyObject {

    /// The gears currently in the scene, in a stable order.
    var placements: [GearPlacement] { get }

    /// Where those gears are on screen this frame.
    var screenTargets: [GearScreenTarget] { get }

    /// Where the mouse's head is on screen this frame, or nil when it is off screen.
    /// The speech bubble hangs off this — the mouse is the one doing the talking.
    var mouseScreenAnchor: CGPoint? { get }

    /// Re-lays the scene for a new role assignment, animated over `AppDuration`.
    func apply(assignment: GearRoleAssignment, animated: Bool)

    /// One physics frame: gear angles and the cheese's height.
    func apply(state: GearTrainState, ratio: Double)

    /// Choreography the level's director drives.
    func setMousePose(_ pose: MouseSprite)
    func setRopeVisible(_ visible: Bool)
    func setHighlightedGears(_ ids: Set<UUID>)

    /// Removes everything this scene owns, including the session-side anchor.
    /// The ARSession itself is never touched.
    func teardown()
}
