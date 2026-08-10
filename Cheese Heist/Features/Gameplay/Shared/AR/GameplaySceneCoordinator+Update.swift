//
//  GameplaySceneCoordinator+Update.swift
//  Cheese Heist
//
//  Everything that writes to an already-built scene: the role relayout, one physics
//  frame, and the choreography switches the level's director drives.
//

import ARKit
import RealityKit
import simd

extension GameplaySceneCoordinator: CraneSceneProviding {

    // MARK: - Assignment

    /// Re-lays the scene for a new role assignment.
    ///
    /// Animated, never snapped: the child taps the other gear and the mouse walks
    /// across, the rope swings over, the cheese follows. A snap reads as a glitch and
    /// hides the very thing being taught — that the roles have exchanged.
    func apply(assignment: GearRoleAssignment, animated: Bool) {
        guard let next = SceneLayoutFromAssignment.layout(
            gears: placements, assignment: assignment, mouseHeight: Self.mouseHeight
        ) else { return }

        setAssignment(assignment)
        setLayout(next)

        restyleTwins(for: assignment)
        move(mouseSprite?.entity, to: next.mousePerch, animated: animated)
        move(payloadHolder, to: next.ropeAnchor, animated: animated)
    }

    private func restyleTwins(for assignment: GearRoleAssignment) {
        for (id, twin) in twinsByID {
            guard let role = assignment.role(of: id) else { continue }
            GearTwinEntityFactory.restyle(twin, as: role)
        }
    }

    private func move(_ entity: Entity?, to position: simd_float3, animated: Bool) {
        guard let entity else { return }
        guard animated else {
            entity.position = position
            return
        }
        var target = entity.transform
        target.translation = position
        entity.move(to: target, relativeTo: entity.parent,
                    duration: AppDuration.transition, timingFunction: .easeInOut)
    }

    // MARK: - Physics

    /// One physics frame. Reads the state; decides nothing.
    func apply(state: GearTrainState, ratio: Double) {
        guard let layout = currentLayout else { return }

        // Meshed gears turn in OPPOSITE directions — matching signs would quietly teach
        // the wrong thing about how a gear train works. The follower's angle is DERIVED
        // from the driver's rather than integrated on its own, which is what stops float
        // drift visibly unmeshing the teeth over a long run.
        twinsByID[layout.driver.id]?.spin.orientation =
            simd_quatf(angle: Float(state.driverAngle), axis: simd_float3(0, 0, 1))
        twinsByID[layout.follower.id]?.spin.orientation =
            simd_quatf(angle: Float(state.followerAngle(ratio: ratio)), axis: simd_float3(0, 0, 1))

        setPayloadHeight(Float(state.height))
    }

    /// Moves the cheese up from its resting position and shortens the rope to match.
    private func setPayloadHeight(_ height: Float) {
        guard let rope = ropeLine else { return }
        setAppliedHeight(height)
        let drop = max(rope.restingDrop - height, 0.001)
        rope.setLength(drop)
        cheeseEntity?.position = simd_float3(0, -drop, 0)
    }

    // MARK: - Choreography

    func setMousePose(_ pose: MouseSprite) {
        mouseSprite?.setPose(pose)
    }

    func setRopeVisible(_ visible: Bool) {
        ropeLine?.entity.isEnabled = visible
        cheeseEntity?.isEnabled = visible
    }

    func setHighlightedGears(_ ids: Set<UUID>) {
        for (id, ring) in ringsByID {
            ring.isEnabled = ids.contains(id)
        }
    }

    // MARK: - Per-frame ticks

    /// Fed by `SceneUpdateTicker`, FIRST in the fixed order: alignment before physics,
    /// so the lift writes into an already-corrected frame.
    func smoothAlignment(deltaTime: Float) {
        guard let root = contentRoot,
              let corrected = alignment.smooth(deltaTime: deltaTime) else { return }
        root.transform = Transform(matrix: corrected)
    }

    /// A fresh 6 Hz measurement of where the crane is. Sets a target; moves nothing.
    func correctAlignment(toward frame: CraneFrame, session: ARSession?) {
        guard let anchorWorld = anchorWorldTransform() else { return }

        // ARKit is re-fitting its map. A measurement taken against a world that is
        // about to shift is not evidence about where the crane is, and folding it in
        // would fight the relocalisation rather than survive it.
        guard let tracking = session?.currentFrame?.camera.trackingState,
              case .normal = tracking else { return }

        alignment.correct(toward: frame, anchorInverse: anchorWorld.inverse)
    }

    /// Keeps the cheese resting on the table rather than at a fixed drop, and keeps
    /// the billboards facing the camera. Runs LAST, so the overlay reads the same
    /// frame it draws.
    func refreshProjection(session: ARSession?) {
        refreshRestingDrop(session: session)

        if let view {
            billboards.update(cameraTransform: view.cameraTransform.matrix)
        }

        setScreenTargets(projector?.targets(
            for: placements, assignment: assignment, root: contentRoot
        ) ?? [])
    }

    /// Re-measures the table under the follower and drops the cheese onto it.
    ///
    /// A scene concern, not a physics one: `tuning.liftHeight` still governs how far
    /// the cheese TRAVELS, and this only decides where it starts.
    private func refreshRestingDrop(session: ARSession?) {
        guard let session, let root = contentRoot, let layout = currentLayout else { return }

        let world = root.convert(position: layout.ropeAnchor, to: nil)
        surface.update(session: session, below: world)

        // Re-render on the ticks where the measurement actually moved the table.
        // `setRestingDrop` only stores the number, and the only other thing that draws
        // the rope is a physics frame — which does not happen until the child first
        // cranks. Without this the cheese hangs at the 9cm fallback right through the
        // intro dialogue and both teaching beats, which is the entire window in which
        // the child is looking at the scene for the first time.
        let drop = surface.restingDrop(below: world, fallback: Self.fallbackRestingDrop)
        guard ropeLine?.setRestingDrop(drop) == true else { return }
        setPayloadHeight(lastAppliedHeight)
    }

    private func anchorWorldTransform() -> simd_float4x4? {
        contentRoot?.parent?.transformMatrix(relativeTo: nil)
    }
}
