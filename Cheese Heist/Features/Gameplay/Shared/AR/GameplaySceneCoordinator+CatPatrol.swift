//
//  GameplaySceneCoordinator+CatPatrol.swift
//  Cheese Heist
//
//  The cat that patrols in front of the crane for the whole of a Level 2 attempt.
//
//  ═══ IN FRONT OF THE CRANE, NOT ROUND IT. ═══
//
//  The beat is the front half of the circle only, and the cat turns round at each end
//  rather than continuing behind the beam — `Level2Tuning.catOrbitArc`, and the reason is
//  in `OrbitPatrolModel`'s header. The cutscene's cat still walks the whole circle; there
//  is nothing in the middle of its own for it to disappear behind.
//
//  ═══ LEVEL 2 ONLY, AND OPTED INTO RATHER THAN BRANCHED ON. ═══
//
//  `build` is shared between both levels and stays that way: there is no `if level == 2`
//  anywhere in the coordinator. Level 2 calls `startCatPatrol()` once, immediately after
//  the build, and ticks it; Level 1 calls neither and gets exactly the scene it had. The
//  only level-shaped thing here is which level dials the number — `AppServices`.
//
//  ═══ THE CAT ADDS NO STEP TO THE LEVEL. ═══
//
//  It is not a phase, not an event, not an input target, and the phase machine has never
//  heard of it. It appears with the gears, the mouse, the rope and the cheese on the
//  detection lock, and it keeps walking until the coordinator is torn down — which means
//  through cranking, through the stall shake, and through the result overlay, because
//  success is an overlay and not a route and the AR scene under it is never dismantled.
//  Nothing about the game state reaches it, so there is nothing for it to get out of sync
//  with.
//
//  ═══ IT WALKS ON THE TABLE, WHICH IS MEASURED, NOT ASSUMED. ═══
//
//  The crane frame's origin is the midpoint of the two gear AXLES, so local y = 0 is
//  partway up the crane — a cat placed there would be padding through thin air at gear
//  height. The table is `restingDrop` below the follower's axle, and that is a live
//  `SupportSurfaceEstimator` measurement that improves while the child plays (it starts at
//  the 9cm fallback). So the orbit's centre is refreshed every frame from the same number
//  the cheese rests on, and the cat's feet and the cheese's underside are on the same
//  plane by construction rather than by two constants agreeing.
//
//  The cat model is loaded through `CutsceneStageEntity` on purpose: that type is the only
//  place that knows how to get this skinned asset out of `meong.usdz` at the right size,
//  the right way up and the right distance from the origin, and every one of those was a
//  bug once. Its cheese is simply never parented in — Level 2 has a cheese of its own.
//

import RealityKit
import simd

extension GameplaySceneCoordinator {

    /// Adds the cat and starts it walking. Called once, right after `build`.
    ///
    /// Idempotent for the same reason `build` is: a second cat would be a second driver
    /// writing the same transform, and the two would fight over it every frame.
    func startCatPatrol() {
        guard catPatrol == nil,
              let root = contentRoot,
              let stage = CutsceneStageEntity.make() else { return }

        // On top of the authored cat:cheese ratio, never instead of it — see `catScale`.
        stage.catHolder.scale *= Level2Tuning.catScale
        root.addChild(stage.catHolder)

        catPatrol = CatOrbitDriver(
            cat: stage,
            radius: Level2Tuning.catOrbitRadius,
            speed: Level2Tuning.catOrbitSpeed,
            arc: Level2Tuning.catOrbitArc
        )
    }

    /// One frame of the prowl. A no-op in Level 1, where there is no cat.
    func advanceCatPatrol(deltaTime: Float) {
        guard let cat = catPatrol else { return }
        cat.centre = simd_float3(0, tableHeight, 0)
        cat.advance(deltaTime: deltaTime)
    }

    /// Crane-local height of the table the cat walks on: the follower's axle, less the
    /// drop the rope is currently paying out to reach it.
    private var tableHeight: Float {
        guard let layout = currentLayout, let rope = ropeLine else { return 0 }
        return layout.ropeAnchor.y - rope.restingDrop
    }
}
