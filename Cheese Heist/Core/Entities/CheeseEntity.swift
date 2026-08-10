//
//  CheeseEntity.swift
//  Cheese Heist
//
//  The payload. Loaded from `Cheese.usdc`, whose scale, up-axis and origin are all
//  unverified (risk R-L3) — which is exactly the class of problem `GearMeshNormaliser`
//  already solves, so it is normalised through that rather than corrected with a
//  hand-tuned scale constant beside it.
//
//  It is a Blender export of a whole scene: a camera, two sphere lights, a dome light
//  and a cheese authored 1.19m tall. All three of those facts have bitten. The camera
//  and lights go through `LoadedModelSanitiser` — before measuring, not just before
//  rendering — and the size then comes out of `ModelBounds`, which counts meshes only.
//

import RealityKit
import os

@MainActor
enum CheeseEntity {

    /// How big the cheese reads on the table, longest edge, in metres.
    ///
    /// Level 1's payload is 10g of physics; this is the number that decides whether it
    /// looks like something a mouse would want. Roughly a LEGO 4x4 plate.
    static let longestEdge: Float = 0.032

    static func make() -> Entity? {
        guard let model = try? Entity.load(named: "Cheese") else {
            Logger.scene.error("Cheese.usdc is not in the bundle")
            return nil
        }

        LoadedModelSanitiser.strip(from: model)

        guard let normalised = GearMeshNormaliser.normalisedProp(
            model, targetLongestEdge: longestEdge
        ) else {
            Logger.scene.error("Cheese.usdc has no volume")
            return nil
        }

        return normalised
    }
}
