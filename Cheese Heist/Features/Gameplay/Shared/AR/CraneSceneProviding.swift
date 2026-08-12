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

    /// How far the cheese can rise before it reaches the follower's axle, in metres.
    ///
    /// A MEASURED distance, not a tuning constant: it is the drop to the table the child
    /// actually built, less the cheese's own height. The lift runs against this so that
    /// "reached the ceiling" and "the cheese is up at the gear with no rope left" are
    /// the same event rather than two that happen to coincide on one crane.
    var maximumLift: Float { get }

    /// Re-lays the scene for a new role assignment, animated over `AppDuration`.
    func apply(assignment: GearRoleAssignment, animated: Bool)

    /// One physics frame: gear angles and the cheese's height.
    func apply(state: GearTrainState, ratio: Double)

    /// Choreography the level's director drives.
    ///
    /// There is no `setHighlightedGears` any more. The twins were ringed with an unlit
    /// wireframe disc, which over a real grey gear at arm's length rendered as a white
    /// scribble across the part — a "blueprint" laid over the very thing it was pointing
    /// at. Which gear is which is carried by the role labels and the spotlight, both of
    /// which sit BESIDE the gear rather than on top of it.
    func setMousePose(_ pose: MouseSprite)
    func setRopeVisible(_ visible: Bool)

    /// Removes everything this scene owns, including the session-side anchor.
    /// The ARSession itself is never touched.
    func teardown()
}
