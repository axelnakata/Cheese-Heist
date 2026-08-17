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

    /// Fires the success burst between the gear pair and the mouse — the two are only
    /// ever a gear's-width apart (`SceneLayoutFromAssignment.perch`), so one burst at
    /// their midpoint reads as "on the gears, around the mouse" without needing two.
    /// A touch above the beam so it reads over the mesh rather than through it.
    func playCelebration(starCount: Int) {
        guard let root = contentRoot, let layout = currentLayout else { return }

        let gearMidpoint = (layout.driver.local + layout.follower.local) / 2
        let clearance = GearGeometry.tipRadius(of: layout.driver.type)
        let position = (gearMidpoint + layout.mousePerch) / 2 + simd_float3(0, clearance, 0)

        ResultEffectDriver.play(starCount: starCount, at: position, on: root)
    }
}
