//
//  GameplaySceneCoordinator.swift
//  Cheese Heist
//
//  Owns the single `ARAnchor`, its `AnchorEntity`, the identity `contentRoot`, and
//  every entity handle. NOTHING ELSE ADDS OR REMOVES ENTITIES.
//
//  ═══ ONE ANCHOR, NOT FIVE ═══
//
//  Every virtual object is a child of one entity anchored to the measured crane frame,
//  positioned in that frame's local coordinates. This is the fix for the alignment
//  drifting: with the gears, mouse, rope and cheese each pinned to their own world
//  position, each carried its own error and they could disagree with each other on
//  screen. Now there is exactly one placement to get right and the rest are fixed
//  offsets that cannot slide relative to it.
//
//  The frame's local axes are +X along the beam, +Y world up, +Z out of the beam's
//  face — so gear meshes (built with their axis along +Z) need no rotation at all, and
//  the rope hangs along local -Y, which gravity guarantees is world down.
//
//  ═══ THE ANCHOR HOLDS THE SCENE. THE DETECTOR ONLY CORRECTS IT. ═══
//
//  An `ARAnchor` registered with the session is carried along as ARKit refines its map,
//  which it does constantly while the child walks around. That correction runs at 60Hz,
//  costs nothing, has no latency, and on a LiDAR iPad in a small static scene is
//  accurate to a few millimetres. It keeps working when the gears are behind a hand,
//  out of frame, or motion-blurred past recognition.
//
//  So `contentRoot`'s LOCAL transform starts at identity and stays near it. It carries
//  only `CraneAlignmentFilter`'s slowly-improving correction to where the crane sits;
//  the anchor carries everything to do with where the CHILD is. Between corrections it
//  is not written at all, so ARKit's answer reaches the screen untouched.
//
//  ═══ LIFETIME IS ONE ATTEMPT, NOT ONE SESSION ═══
//
//  Retry calls `teardown()` and a fresh coordinator is built on the next lock. That is
//  how retry and the one-`session.run`-per-process invariant coexist.
//

import ARKit
import RealityKit
import simd
import os

@MainActor
final class GameplaySceneCoordinator {

    /// How tall the mouse stands. Shared with the layout so the perch matches.
    static let mouseHeight = MouseSpriteEntity.height

    /// Where the cheese rests before the table has been measured, in metres below the
    /// follower's axle.
    static let fallbackRestingDrop: Float = 0.09

    private(set) var placements: [GearPlacement] = []
    private(set) var screenTargets: [GearScreenTarget] = []

    // MARK: Scene graph

    private weak var arView: ARView?
    private var craneARAnchor: ARAnchor?
    private var anchorEntity: AnchorEntity?
    private(set) var contentRoot: Entity?

    private var twins: [UUID: GearTwin] = [:]
    private var rings: [UUID: ModelEntity] = [:]
    private var mouse: MouseSpriteEntity?
    private var ropeCheeseHolder: Entity?
    private var rope: RopeEntity?
    private var cheese: Entity?

    // MARK: Collaborators

    let alignment = CraneAlignmentFilter()
    let billboards = BillboardSystem()
    let surface = SupportSurfaceEstimator()
    private(set) var projector: GearScreenProjector?

    private(set) var assignment: GearRoleAssignment?
    private var layout: SceneLayout?
    private var liftHeight: Float = 0.06

    // MARK: - Build

    /// Builds the scene once, on the detection lock.
    ///
    /// Defensive against a second call: placing twice would leave an orphaned second
    /// set of gears, mouse, rope and cheese in the scene — one animating, the rest
    /// frozen.
    func build(
        frame: CraneFrame,
        gears: [DetectedGear],
        assignment: GearRoleAssignment,
        liftHeight: Float,
        in arView: ARView
    ) {
        guard contentRoot == nil, gears.count == 2 else { return }

        self.arView = arView
        self.liftHeight = liftHeight
        self.assignment = assignment

        let anchor = CraneAnchorBuilder.build(frame: frame, in: arView)
        craneARAnchor = anchor.arAnchor
        anchorEntity = anchor.anchorEntity
        contentRoot = anchor.contentRoot
        projector = GearScreenProjector(arView: arView)

        // Measured once, here, and never rewritten. These are fixed LEGO geometry: two
        // gear centres a known distance apart on a beam, and everything else hung off
        // them. Re-solving them per frame could only feed the detector's box jitter
        // into a rig that should be rigid.
        placements = gears.map {
            GearPlacement(id: $0.id, type: $0.type, local: flattened(frame.localPoint($0.worldPosition)))
        }

        buildEntities(root: anchor.contentRoot)
        apply(assignment: assignment, animated: false)
        Logger.scene.info("scene built on \(gears.count) gears")
    }

    /// Local Z is ~0 by construction — the gears were solved as ray/plane hits on this
    /// very plane — so it is flattened rather than carried as float noise.
    private func flattened(_ local: simd_float3) -> simd_float3 {
        simd_float3(local.x, local.y, 0)
    }

    private func buildEntities(root: Entity) {
        for placement in placements {
            guard let twin = GearTwinEntityFactory.make(type: placement.type, role: .driver) else { continue }
            twin.holder.position = placement.local
            root.addChild(twin.holder)
            twins[placement.id] = twin

            let ring = GearHighlightRing.make(for: placement.type)
            ring.isEnabled = false
            twin.holder.addChild(ring)
            rings[placement.id] = ring
        }

        if let sprite = MouseSpriteEntity() {
            root.addChild(sprite.entity)
            billboards.register(sprite.entity)
            mouse = sprite
        }

        let holder = Entity()
        root.addChild(holder)
        ropeCheeseHolder = holder

        let drop = Self.fallbackRestingDrop
        let line = RopeEntity(restingDrop: drop)
        holder.addChild(line.entity)
        rope = line

        if let wedge = CheeseEntity.make() {
            wedge.position = simd_float3(0, -drop, 0)
            holder.addChild(wedge)
            billboards.register(wedge)
            cheese = wedge
        }
    }

    // MARK: - Teardown

    /// Removes everything this coordinator owns. **Never** pauses the ARSession.
    ///
    /// The session-side anchor has to go too — clearing the scene's anchors only
    /// removes the RealityKit half, leaving ARKit tracking a crane that no longer has
    /// anything attached to it.
    func teardown() {
        if let craneARAnchor { arView?.session.remove(anchor: craneARAnchor) }
        if let anchorEntity { arView?.scene.removeAnchor(anchorEntity) }

        billboards.removeAll()
        alignment.reset()
        surface.reset()

        craneARAnchor = nil
        anchorEntity = nil
        contentRoot = nil
        projector = nil
        twins = [:]
        rings = [:]
        mouse = nil
        rope = nil
        cheese = nil
        ropeCheeseHolder = nil
        placements = []
        screenTargets = []
        layout = nil
        assignment = nil
    }

    // MARK: - Handles for the update extension

    var currentLayout: SceneLayout? { layout }
    func setLayout(_ next: SceneLayout?) { layout = next }
    var twinsByID: [UUID: GearTwin] { twins }
    var ringsByID: [UUID: ModelEntity] { rings }
    var mouseSprite: MouseSpriteEntity? { mouse }
    var ropeLine: RopeEntity? { rope }
    var cheeseEntity: Entity? { cheese }
    var payloadHolder: Entity? { ropeCheeseHolder }
    var view: ARView? { arView }
    var currentLiftHeight: Float { liftHeight }
    func setAssignment(_ next: GearRoleAssignment) { assignment = next }
    func setScreenTargets(_ next: [GearScreenTarget]) { screenTargets = next }
}
