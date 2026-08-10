//
//  CheeseEntity.swift
//  Cheese Heist
//
//  The payload. Loaded from `Cheese.usdc`, whose scale, up-axis and origin are all
//  unverified (risk R-L3) — which is exactly the class of problem `GearMeshNormaliser`
//  already solves, so it is normalised through that rather than corrected with a
//  hand-tuned scale constant beside it.
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

        guard let normalised = GearMeshNormaliser.normalisedProp(
            model, targetLongestEdge: longestEdge
        ) else {
            Logger.scene.error("Cheese.usdc has no volume")
            return nil
        }

        return normalised
    }
}
