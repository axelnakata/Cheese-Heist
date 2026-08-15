//
//  MouseModelEntity.swift
//  Cheese Heist
//
//  The mouse: `Resources/3DModels/Props/Mouse.usdz`, grounded at its own feet so a
//  caller's `.position` is exactly where the mouse stands — no half-height offset the
//  way the flat sprite needed.
//
//  Replaces the billboarded quad this used to be. A real rig reads correctly from any
//  angle the child walks to, so nothing here registers with `BillboardSystem` — see
//  `GameplaySceneCoordinator.buildMouse`.
//
//  ═══ NOT NORMALISED THROUGH `GearMeshNormaliser`. ═══
//
//  That measures `MeshResource.bounds`, which for a skinned mesh is the BIND-POSE
//  vertex box — not the pose the renderer actually draws. This rig's bind pose (see
//  the raw `bindTransforms` in the USD) is nowhere near its rest pose, the same class
//  of mismatch that shoved the cutscene cat across the room — see
//  `CutsceneStageEntity`. `ModelBounds.measureSkeleton` reads the joints' REST pose
//  instead, accumulated down the parent chain, which is what `init` scales and grounds
//  against.
//
//  ═══ THE FIRST EXPORT OF THIS ASSET HAD NO SKELETON WORTH THE NAME. ═══
//
//  That file's mouse was a single placeholder joint driving three blend shapes, and
//  bind-pose measurement against it produced a container the wrong shape entirely —
//  the mouse rendered as a warped fragment floating well above the crane. This one
//  carries a real 25-joint rig (`Root/Hips/Spine1/…`, paws, ears, a tail), and its
//  paws sit a little ABOVE `Root`, which is exactly where a Blender rigger's "root at
//  the floor" convention puts it — confirmed on the simulator: `Root`'s rest-pose Y is
//  ~0 while every paw joint reads Y > 0. So grounding on the skeleton's own minimum
//  needs no separate assumption about which joint is "the feet".
//
//  ═══ THE ANIMATION PLAYS. ═══
//
//  `Idle_Body` drives the same three blend shapes as before (still `Invalid` — nothing
//  imports blend-shape animation here) but ALSO drives every joint's rotation,
//  translation and scale across 96 frames. RealityKit imports THAT half as a genuine
//  `SampledAnimation<JointTransforms>`, duration ~3.96s — confirmed by dumping
//  `entity.availableAnimations` on the simulator rather than trusting the raw USD.
//  `walkAnimation` picks it out by being the only take with a finite, non-zero
//  duration, so the same lookup would fall back to silence again if a future export
//  regressed.
//

import RealityKit
import os
import simd

@MainActor
final class MouseModelEntity {

    /// How tall the mouse stands, in metres. Carried over from the flat sprite's own
    /// tuning. Sized against the crane rather than the gear it stands behind: the same
    /// mouse has to look right behind an 8T and behind a 40T.
    static let height: Float = 0.055

    /// The grounded, scaled container: ours to position; never to reparent.
    let entity: Entity

    private let animated: Entity?
    private let walkAnimation: AnimationResource?
    private var isAnimating = false

    /// Whether `setAnimating(true)` will actually move anything. Exposed for
    /// `BundledAssetTests` — a regression here reads on device as a mouse that stands
    /// perfectly still no matter how the child cranks, with nothing else visibly wrong.
    var canAnimate: Bool { walkAnimation != nil }

    init?() {
        guard let model = try? Entity.load(named: "Mouse") else {
            Logger.scene.error("Mouse.usdz is not in the bundle")
            return nil
        }

        // Before measuring, not just before rendering — see `LoadedModelSanitiser`.
        LoadedModelSanitiser.strip(from: model)

        let owner = Self.animationOwner(in: model)
        animated = owner
        walkAnimation = owner.flatMap(Self.walkTake)

        guard let bounds = ModelBounds.measureSkeleton(model), bounds.extents.y > 0 else {
            Logger.scene.error("Mouse.usdz has no measurable skeleton")
            return nil
        }

        // Composed on a wrapper, never onto `model.transform` — same reasoning as
        // `GearMeshNormaliser`. Only Y is corrected: `bounds` is already centred on X
        // (the rig is left-right symmetric) and already stands with its floor — see
        // the header — at `bounds.min.y`, so grounding is "subtract whatever that
        // measures" rather than an assumed zero.
        let holder = Entity()
        holder.addChild(model)
        holder.transform = Transform(
            scale: simd_float3(repeating: Self.height / bounds.extents.y),
            translation: simd_float3(0, -(Self.height / bounds.extents.y) * bounds.min.y, 0)
        )
        entity = holder
    }

    /// Plays the crank animation while the joystick is engaged; stops the moment it
    /// isn't. Idempotent, so the per-frame physics tick can call this unconditionally
    /// without spamming `playAnimation` sixty times a second.
    func setAnimating(_ animating: Bool) {
        guard animating != isAnimating else { return }
        isAnimating = animating

        guard let animated, let walkAnimation else { return }
        if animating {
            animated.playAnimation(walkAnimation.repeat())
        } else {
            animated.stopAllAnimations()
        }
    }

    /// The deepest descendant carrying animations — see
    /// `CutsceneStageEntity.animationOwner` for why deepest and not first.
    private static func animationOwner(in root: Entity) -> Entity? {
        var deepest: Entity?
        var queue = [root]
        while !queue.isEmpty {
            let entity = queue.removeFirst()
            if !entity.availableAnimations.isEmpty { deepest = entity }
            queue.append(contentsOf: entity.children)
        }
        return deepest
    }

    /// The longest FINITE, non-zero take in the file. The blend-shape half of
    /// `Idle_Body` still imports as `InvalidAnimationDefinition` (duration 0), so this
    /// is also what filters that out and leaves the real joint animation.
    private static func walkTake(from entity: Entity) -> AnimationResource? {
        let takes = entity.availableAnimations.filter {
            $0.definition.duration.isFinite && $0.definition.duration > 0
        }
        guard let take = takes.max(by: { $0.definition.duration < $1.definition.duration }) else {
            Logger.scene.error("Mouse.usdz exposed no playable animation")
            return nil
        }
        return take
    }
}
