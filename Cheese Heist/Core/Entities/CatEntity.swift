//
//  CatEntity.swift
//  Cheese Heist
//
//  PRD-Cutscene §7.5 — loads `thundercat.usdz` and pulls the walk cycle out of it.
//
//  ═══ THE FILE CARRIES MORE THAN ONE ANIMATION, AND ONLY A SLICE OF ONE IS WANTED. ═══
//
//  `thundercat.usdz` is a flattened Reality Composer Pro scene: a Blender `SkelRoot`
//  with a baked take, wrapped in an RCP layer that adds a Timeline of orbit and spin
//  actions. Taking `availableAnimations.first` is a coin toss between the two, and the
//  Timeline's orbit is precisely the thing we drive in code instead — playing it would
//  fight `OrbitPatrolModel` for the cat's transform.
//
//  So the take is chosen by duration, then trimmed to the walk cycle. `C5.usda` records
//  the slice exactly: the RCP `AnimationLibrary` cuts at [0, 5.227722, 5.704193] and
//  loops the middle 0.4765 s. Those two numbers are `CutsceneTuning.catWalkClip*`.
//
//  The animation is also played on the entity that actually owns it, not on `holder`.
//  `holder` is a bare `Entity` we create here for the orbit to write into; animations
//  loaded from a file are bound to the subtree they came from, and playing on an
//  unrelated ancestor silently does nothing.
//

import RealityKit
import os

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
        guard let model = try? Entity.load(named: "thundercat") else {
            Logger.cutscene.error("thundercat.usdz is not in the bundle")
            return nil
        }

        LoadedModelSanitiser.strip(from: model)

        guard let normalised = GearMeshNormaliser.normalisedProp(
            model, targetLongestEdge: CutsceneTuning.catBodyLength
        ) else {
            Logger.cutscene.error("thundercat.usdz has no measurable volume")
            return nil
        }

        let holder = Entity()
        holder.addChild(normalised)

        let animated = animationOwner(in: normalised) ?? normalised
        return CatProp(holder: holder, animated: animated, walk: walkClip(from: animated))
    }

    // MARK: - Animation

    /// Breadth-first search for the first descendant carrying animations.
    private static func animationOwner(in root: Entity) -> Entity? {
        var queue = [root]
        while !queue.isEmpty {
            let entity = queue.removeFirst()
            if !entity.availableAnimations.isEmpty { return entity }
            queue.append(contentsOf: entity.children)
        }
        return nil
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
            Logger.cutscene.error("thundercat.usdz exposed no animations")
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
