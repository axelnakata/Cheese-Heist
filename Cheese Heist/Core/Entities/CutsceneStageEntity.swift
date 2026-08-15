//
//  CutsceneStageEntity.swift
//  Cheese Heist
//
//  PRD-Cutscene §7.5 — loads `meong.usdz` ONCE and hands back both props out of it.
//
//  `meong.usdz` is the flattened export of the Reality Composer Pro package in
//  `Docs/cutsceneFixing/`: `catandcheese.usda` composing `tooncat.usdz` and
//  `Cheese-2.usdc`, under a scene layer that switches the imported cameras and lights off
//  and fixes up the materials. The cat and the cheese were placed together in that
//  viewport, so the file already carries the one thing no code here can derive — how big
//  the cat is MEANT to be next to the cheese.
//
//  ═══ THE AUTHORED RATIO IS THE POINT, SO NEITHER PROP IS NORMALISED. ═══
//
//  Every other prop in the app goes through `GearMeshNormaliser`, which measures the mesh
//  and rescales it to a target size. The cat must not: see the next section. So instead of
//  two independent targets, the stage takes ONE scale — measured off the cheese, which is
//  a rigid mesh that measures honestly — and applies it to both. The cheese comes out at
//  `CutsceneTuning.cheeseSize` and the cat comes out wherever the RCP viewport put it
//  relative to the cheese, which is the whole reason the composite file exists.
//
//  Measured on the simulator, authored world extents are cheese 0.876 × 1.190 × 0.482 and
//  cat 0.564 × 1.609 × 2.119 — so at an 8 cm cheese the cat is about 14 cm long and 11 cm
//  tall. `cheeseSize` is therefore the single knob for the whole stage.
//
//  ═══ AND `ModelBounds` CANNOT MEASURE A SKINNED CAT. ═══
//
//  This is the bug that made the cat look like a mosquito, and it is worth stating exactly
//  because nothing about it is visible in a debugger. `ModelBounds` and
//  `Entity.visualBounds` both read `MeshResource.bounds`, which for a skinned mesh is the
//  BIND-POSE vertex box — and this rig's bind pose is parked 190 units from the origin:
//  `mesh.bounds` reports extents (1.795, 5.765, 3.706) centred at (0, 113.7, 190.0), while
//  the rest pose the renderer actually draws spans (0.564, 1.609, 2.119) sitting ON the
//  origin. Normalising against the bind box therefore did two wrong things at once: it
//  divided by the wrong size, and — far worse — it "recentred" the prop by translating it
//  by minus that 190-unit offset, which shoved the cat about seven metres away from the
//  anchor. It was never small. It was across the room.
//
//  So the cat is used exactly as authored: composed transform kept, scale untouched, and
//  only its X/Z placement zeroed because the orbit owns that. Its authored height is kept
//  too — RCP grounded it, and the accumulated rest-pose joints confirm its feet sit at
//  y = 0. The cheese, being rigid, is grounded by measurement instead.
//
//  ═══ THE STAGE'S UP-AXIS CORRECTION IS KEPT — FOR BOTH. ═══
//
//  `meong.usda` declares `upAxis = "Z"`, so `Entity.load` puts a −90°-about-X rotation on
//  the loaded root, and `transformMatrix(relativeTo: nil)` is what carries it down onto a
//  prop that is about to be reparented. Dropping it stands the cat on its tail: with the
//  correction the cat measures length 2.119 (Z) > height 1.609 (Y) > width 0.564 (X),
//  which is a four-legged animal; without it, height and length swap.
//

import RealityKit
import os
import simd

/// The cutscene's two props, out of one file.
struct CutsceneStage {
    /// Sits at the stage origin, resting on the plane. Never moved again.
    let cheese: Entity
    /// Positioned and turned by the orbit. Never carries the model's own transform.
    let catHolder: Entity
    /// The descendant that owns the baked animations — the one to play on.
    let catAnimated: Entity
    /// The looping walk cycle. `nil` when the file carried no usable take.
    let catWalk: AnimationResource?
}

@MainActor
enum CutsceneStageEntity {

    static func make() -> CutsceneStage? {
        guard let scene = try? Entity.load(named: "meong") else {
            Logger.cutscene.error("meong.usdz is not in the bundle")
            return nil
        }
        guard let cat = scene.findEntity(named: "tooncat"),
              let cheese = scene.findEntity(named: "Cheese_2") else {
            Logger.cutscene.error("meong.usdz is missing \"tooncat\" or \"Cheese_2\"")
            return nil
        }

        // Before measuring, not just before rendering — see `LoadedModelSanitiser`. The
        // RCP layer already deactivates the imported lights; this catches any it missed.
        LoadedModelSanitiser.strip(from: scene)

        guard let bounds = ModelBounds.measure(cheese) else {
            Logger.cutscene.error("Cheese_2 has no mesh in it")
            return nil
        }
        let longest = max(bounds.extents.x, max(bounds.extents.y, bounds.extents.z))
        guard longest > 0 else {
            Logger.cutscene.error("Cheese_2 has no measurable volume")
            return nil
        }
        let scale = CutsceneTuning.cheeseSize / longest

        let animated = animationOwner(in: cat) ?? cat
        let stage = CutsceneStage(
            cheese: grounded(detach(cheese, scale: scale)),
            catHolder: detach(cat, scale: scale),
            catAnimated: animated,
            catWalk: walkTake(from: animated)?.repeat()
        )
        Logger.cutscene.info("cutscene stage scale: \(scale, format: .fixed(precision: 4))")
        return stage
    }

    // MARK: - Extraction

    /// One prop, lifted out of the composite into a holder the caller owns.
    ///
    /// The composed world transform is what gets kept — the stage's up-axis correction
    /// lives above the prop, so reading only the prop's own transform loses it. X and Z
    /// go because they are where RCP happened to park the prop and the scene decides that
    /// now; Y stays because it is how high the prop stands, which RCP got right.
    ///
    /// The uniform scale goes on the HOLDER rather than on the prop, so the prop's own
    /// transform is still exactly what the file authored — which matters because the
    /// baked take is a subtree animation and is free to write it back on the first frame.
    private static func detach(_ prop: Entity, scale: Float) -> Entity {
        let composed = prop.transformMatrix(relativeTo: nil)
        prop.removeFromParent()
        prop.transform = Transform(matrix: composed)
        prop.position.x = 0
        prop.position.z = 0

        let holder = Entity()
        holder.addChild(prop)
        holder.scale = simd_float3(repeating: scale)
        return holder
    }

    /// Drops a rigid prop until its underside is on the plane.
    ///
    /// Measured after `detach`, so the box is in world axes with the scale already in it
    /// and no assumption about which way the up-axis correction turned things. Only safe
    /// on a rigid mesh; the cat is grounded by its authoring instead — see the header.
    private static func grounded(_ holder: Entity) -> Entity {
        holder.position.y = -(ModelBounds.measure(holder)?.min.y ?? 0)
        return holder
    }

    // MARK: - Animation

    /// The DEEPEST descendant carrying animations, not the first.
    ///
    /// `availableAnimations` is not confined to the entity that owns the animation — it
    /// propagates up the whole ancestor chain above it too, so a first-hit search returns
    /// an outer Xform. The deepest hit is the true owner, and on this asset it is
    /// `Object_5`, which the runtime dump confirms is the one entity carrying all three of
    /// `ModelComponent`, `SkeletalPosesComponent` and `AnimationLibraryComponent`.
    ///
    /// Playing there also keeps the take INSIDE the skeleton: a subtree animation writes
    /// the transforms it covers, and `Object_5`'s own transform is identity, so there is
    /// nothing for it to disturb. Played higher up it would restore the cat's authored
    /// offset and throw it off the orbit.
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

    /// The longest FINITE take in the file.
    ///
    /// The file exposes three takes, all named "default subtree animation": two 0.833 s
    /// bakes of the cat's `Action`, and one of duration `inf` — Reality Composer Pro's
    /// AnimationLibrary entry with `looping = 1`. Picking "the longest take" picked THAT
    /// one. Nothing about the name separates them, so duration is the only discriminator.
    ///
    /// Internal, and it hands back the take rather than the looping clip, because the test
    /// has to assert on this: `catWalk` is `take.repeat()`, and a repeating resource
    /// reports its own duration as `inf` by construction.
    static func walkTake(from entity: Entity) -> AnimationResource? {
        let takes = entity.availableAnimations.filter { $0.definition.duration.isFinite }
        Logger.cutscene.info("""
            cat takes: \(entity.availableAnimations.count) finite: \(takes.count)
            """)

        guard let take = takes.max(by: { $0.definition.duration < $1.definition.duration })
        else {
            Logger.cutscene.error("tooncat exposed no finite animation")
            return nil
        }
        return take
    }
}
