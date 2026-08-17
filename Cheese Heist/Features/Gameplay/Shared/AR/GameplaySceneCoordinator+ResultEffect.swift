//
//  GameplaySceneCoordinator+ResultEffect.swift
//  Cheese Heist
//
//  The `playResultEffect` half of `CraneSceneProviding` — its own file for the same
//  reason `+Update.swift` is: a protocol conformance this size belongs apart from the
//  class body that owns the entities it reads.
//

import Foundation
import simd

extension GameplaySceneCoordinator {

    /// Fires the burst at the midpoint between the two gears — "on the crane, on the
    /// gears" — a touch above the beam so it reads over the mesh rather than through it.
    func playResultEffect(_ kind: ResultEffectKind) {
        guard let root = contentRoot, let layout = currentLayout else { return }

        let midpoint = (layout.driver.local + layout.follower.local) / 2
        let clearance = GearGeometry.tipRadius(of: layout.driver.type)
        let position = midpoint + simd_float3(0, clearance, 0)

        ResultEffectDriver.play(kind, at: position, on: root)
    }
}
