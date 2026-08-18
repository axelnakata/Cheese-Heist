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
//  ═══ FACING FRONT-RIGHT TOWARD GEAR & VIEWER (+X, +Z). ═══
//
//  See `yaw`. Facing crane-local +X, +Z points the mouse toward the gear and the iPad.
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
//  ═══ THE ANIMATION PLAYS, AND IT NEVER STOPS. ═══
//
//  `Idle_Body` is the breathe-and-blink loop, ~3.96s over 96 frames. The export that
//  first carried it drove the blink through three BLEND SHAPES, and RealityKit imports
//  none of those — the mouse breathed and never blinked. This export drops the blend
//  shapes entirely and adds two real `Eyelid_L`/`Eyelid_R` joints to the rig (25 joints
//  became 27), so the whole clip arrives as one `SampledAnimation<JointTransforms>` —
//  confirmed by dumping `entity.availableAnimations` on the simulator rather than
//  trusting the raw USD.
//
//  It starts in `init` and is never stopped. It used to be gated on the joystick, which
//  is backwards: a mouse that holds its breath the moment the child lets go of the
//  crank reads as a broken model, not a resting one. Nothing outside this file has an
//  opinion about it any more, so it keeps breathing through the lift, through the
//  success overlay, and until the coordinator tears the scene down.
//
//  `idleTake` picks the clip out by being the only take with a finite, non-zero
//  duration, which is also what filters out the importer's zero-length placeholders —
//  so a future export that regressed would fall back to silence rather than to a crash.
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

    /// How far to turn the mouse about its own vertical axis, so it looks the way the
    /// design has it looking.
    ///
    /// The raw asset ships facing front-left (crane-local -X, +Z). A quarter turn (+π/2)
    /// turns it to face front-right (crane-local +X, +Z), looking toward the driver
    /// gear and the viewer as designed in Figma.
    static let yaw: Float = .pi / 2

    /// The grounded, scaled, turned container: ours to position; never to reparent.
    let entity: Entity

    /// Whether the idle loop actually found something to play. Exposed for
    /// `BundledAssetTests` — a regression here reads on device as a mouse that stands
    /// perfectly still, neither breathing nor blinking, with nothing else visibly wrong.
    private(set) var canAnimate = false

    init?() {
        guard let model = try? Entity.load(named: "Mouse") else {
            Logger.scene.error("Mouse.usdz is not in the bundle")
            return nil
        }

        // Before measuring, not just before rendering — see `LoadedModelSanitiser`.
        LoadedModelSanitiser.strip(from: model)

        guard let bounds = ModelBounds.measureSkeleton(model), bounds.extents.y > 0 else {
            Logger.scene.error("Mouse.usdz has no measurable skeleton")
            return nil
        }

        // Composed on a wrapper, never onto `model.transform` — same reasoning as
        // `GearMeshNormaliser`. Only Y is TRANSLATED: `bounds` is already centred on X
        // (the rig is left-right symmetric) and already stands with its floor — see
        // the header — at `bounds.min.y`, so grounding is "subtract whatever that
        // measures" rather than an assumed zero. The yaw is about Y too, so it cannot
        // disturb that: a turn on the vertical axis leaves every height alone.
        let scale = Self.height / bounds.extents.y
        let holder = Entity()
        holder.addChild(model)
        holder.transform = Transform(
            scale: simd_float3(repeating: scale),
            rotation: simd_quatf(angle: Self.yaw, axis: simd_float3(0, 1, 0)),
            translation: simd_float3(0, -scale * bounds.min.y, 0)
        )
        entity = holder

        startIdleLoop(in: model)
    }

    /// Starts the breathe-and-blink loop, once, for good. There is no stop: see the
    /// header.
    private func startIdleLoop(in model: Entity) {
        guard let owner = Self.animationOwner(in: model),
              let idle = Self.idleTake(from: owner) else { return }
        owner.playAnimation(idle.repeat())
        canAnimate = true
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

    /// The longest FINITE, non-zero take in the file. The importer exposes zero-length
    /// placeholders alongside the real clip, so this is also what filters those out.
    private static func idleTake(from entity: Entity) -> AnimationResource? {
        let takes = entity.availableAnimations.filter {
            $0.definition.duration.isFinite && $0.definition.duration > 0
        }
        guard let take = takes.max(by: { $0.definition.duration < $1.definition.duration }) else {
            Logger.scene.error("Mouse.usdz exposed no playable idle animation")
            return nil
        }
        return take
    }
}
