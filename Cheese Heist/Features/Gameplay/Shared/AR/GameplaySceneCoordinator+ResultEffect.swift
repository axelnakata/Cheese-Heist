//
//  GameplaySceneCoordinator+ResultEffect.swift
//  Cheese Heist
//
//  The `playCelebration` half of `CraneSceneProviding` — its own file for the same
//  reason `+Update.swift` is: a protocol conformance this size belongs apart from the
//  class body that owns the entities it reads.
//

import Foundation
import simd

extension GameplaySceneCoordinator {

    /// Fires the success burst directly around the mouse perched on the driver gear.
    /// Anchored on the mouse's upper body so the golden sparkle burst erupts visibly
    /// in full view of the camera right when succeeding with 1–3 stars.
    func playCelebration(starCount: Int) {
        guard starCount >= 1, let root = contentRoot, let layout = currentLayout else { return }

        // Anchor on the mouse: perched on top of the driver gear
        let mouseCenter = layout.mousePerch + simd_float3(0, MouseModelEntity.height * 0.6, 0.01)

        ResultEffectDriver.play(starCount: min(starCount, 3), at: mouseCenter, on: root)
    }
}
