//
//  CatEntity.swift
//  Cheese Heist
//
//  PRD-Cutscene §7.5 — loads `meong.usdz` and pulls the cat and its walk cycle out of it.
//
//  `meong.usdz` is a Reality Composer Pro scene authored to hold the cat NEXT TO a
//  reference cheese, purely so the axis mess `tooncat.usdz`'s Blender/Sketchfab export
//  chain leaves behind could be corrected by eye in the RCP viewport instead of by
//  guessing quaternions blind. Only the cat is pulled out of it at runtime — the
//  reference cheese in the file (`Cheese_2`) is authoring scaffolding, not the payload;
//  the cutscene's actual cheese still comes from `CheeseEntity`, which is shared with
//  Level 1 and has no business depending on a cutscene-only composite file.
//
//  The cat's TRANSLATION from being positioned next to that reference cheese is
//  discarded on extraction — `OrbitPatrolModel`/`CatOrbitDriver` own `holder`'s position
//  every frame, computed fresh from the orbit angle, and a leftover authoring offset
//  would just add a constant error to it. Only the ROTATION is kept: that is the actual
//  axis correction, and it replaces what used to be a hand-tuned `axisCorrection`
//  constant here.
//
//  The file carries one baked take, `Action` (~0.833 s), no Timeline animating the
//  cat's own transform — nothing here fights `OrbitPatrolModel` for it. The
//  selection-by-duration and trim-to-`CutsceneTuning.catWalkClip*` machinery below is
//  kept anyway, so a future asset that ships multiple takes (idle vs. walk, say) still
//  trims correctly without a code change; on a single-take file it degrades to trivially
//  picking that take and copying its full range.
//
//  The animation is also played on the entity that actually owns it, not on `holder`.
//  `holder` is a bare `Entity` we create here for the orbit to write into; animations
//  loaded from a file are bound to the subtree they came from, and playing on an
//  unrelated ancestor silently does nothing.
//

import RealityKit
import os
import simd

struct CatProp {
    /// Positioned and turned by the orbit. Never carries the model's own transform.
    let holder: Entity
    /// The descendant that owns the baked animations — the one to play on.
    let animated: Entity
    /// The trimmed, looping walk cycle. `nil` when the file carried no usable take.
    let walk: AnimationResource?
}

@MainActor
enum CatEntity {

    static func make() -> CatProp? {
        guard let scene = try? Entity.load(named: "meong") else {
            Logger.cutscene.error("meong.usdz is not in the bundle")
            return nil
        }
        guard let cat = scene.findEntity(named: "tooncat") else {
            Logger.cutscene.error("meong.usdz has no \"tooncat\" child")
            return nil
        }
        cat.removeFromParent()

        // Keep the RCP-authored axis correction (rotation); drop the authoring-only
        // position next to the reference cheese — see the header comment.
        cat.transform = Transform(scale: .one, rotation: cat.orientation, translation: .zero)

        LoadedModelSanitiser.strip(from: cat)

        guard let normalised = GearMeshNormaliser.normalisedProp(
            cat, targetLongestEdge: CutsceneTuning.catBodyLength
        ) else {
            Logger.cutscene.error("tooncat has no measurable volume")
            return nil
        }

        let holder = Entity()
        holder.addChild(normalised)

        let animated = animationOwner(in: normalised) ?? normalised
        return CatProp(holder: holder, animated: animated, walk: walkClip(from: animated))
    }

    // MARK: - Animation

    /// The DEEPEST descendant carrying animations, not the first.
    ///
    /// `availableAnimations` is not confined to the entity that owns the animation — it
    /// propagates up the whole ancestor chain above it too. On `tooncat.usdz` every
    /// entity from the loaded root down to the `SkelRoot`'s own parent reports a
    /// non-empty list, so a first-hit search grabbed an outer Xform instead of the
    /// `SkelRoot` itself, and played the walk cycle on an entity with no skin binding —
    /// which is what sent the cat to some other transform entirely rather than doing
    /// nothing. The deepest hit is always the true owner: nothing propagates downward.
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

    /// The walk cycle, trimmed out of the longest take and set to loop.
    ///
    /// Falls back to looping the whole take if nothing in the file is long enough to
    /// contain the slice — a cat walking its entire baked performance on repeat is
    /// wrong, but it is visibly wrong, which beats a cat that slides without moving
    /// its legs and looks like a physics bug.
    private static func walkClip(from entity: Entity) -> AnimationResource? {
        let takes = entity.availableAnimations
        guard !takes.isEmpty else {
            Logger.cutscene.error("tooncat exposed no animations")
            return nil
        }

        let longest = takes.max { $0.definition.duration < $1.definition.duration }
        guard let take = longest else { return nil }

        Logger.cutscene.info("""
            cat takes: \(takes.count) longest=\
            \(take.definition.duration, format: .fixed(precision: 3))s
            """)

        guard take.definition.duration >= CutsceneTuning.catWalkClipEnd else {
            Logger.cutscene.error("cat take is shorter than the walk slice — looping whole")
            return take.repeat()
        }

        var view = AnimationView(
            source: take.definition,
            trimStart: CutsceneTuning.catWalkClipStart,
            trimEnd: CutsceneTuning.catWalkClipEnd
        )
        view.repeatMode = .repeat

        guard let trimmed = try? AnimationResource.generate(with: view) else {
            Logger.cutscene.error("could not trim the cat walk clip — looping whole take")
            return take.repeat()
        }
        return trimmed
    }
}
