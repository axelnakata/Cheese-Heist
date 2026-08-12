//
//  GearMeshFactory.swift
//  Cheese Heist
//
//  Loads the bundled LEGO Technic gear for a tooth count and hands back an entity
//  lying in XY with its axis along +Z.
//
//  WHY +Z AND NO ROTATION AT THE CALL SITE:
//  The crane frame's local +Z *is* the gear axis (see `CraneFrame`), so a mesh built
//  this way drops into the scene with identity rotation. That is the whole mitigation
//  for parent PRD risk R-02 — deriving a gear's axis from a 2D box — and it is why no
//  per-gear `rotation(from:to:)` exists anywhere in this app.
//
//  Loaded models are cached: `Entity.load` is expensive and the same three gears are
//  asked for on every retry.
//

import RealityKit
import os
import simd

enum GearMeshFactory {

    /// Loaded, normalised prototypes by tooth count. Cloned per use.
    private static var cache: [Int: Entity] = [:]

    /// A ready-to-place gear, axis along +Z in its own space, sized from LEGO's
    /// module-1 spec rather than from whatever the file happened to contain.
    ///
    /// Returns nil when the model is missing or has no volume. Callers treat that as
    /// "no twin for this gear" rather than substituting a stand-in: a wrongly-sized
    /// gear sitting over the real one teaches something false about gear size, which
    /// is the entire lesson.
    @MainActor
    static func entity(for type: GearType) -> Entity? {
        if let cached = cache[type.teeth] { return cached.clone(recursive: true) }

        guard let model = try? Entity.load(named: type.modelName) else {
            Logger.scene.error("\(type.modelName, privacy: .public) is not in the bundle")
            return nil
        }

        LoadedModelSanitiser.strip(from: model)

        guard let normalised = GearMeshNormaliser.normalisedDisc(
            model, targetDiameter: GearGeometry.tipDiameter(teeth: type.teeth)
        ) else {
            Logger.scene.error("\(type.modelName, privacy: .public) has no volume")
            return nil
        }

        cache[type.teeth] = normalised
        return normalised.clone(recursive: true)
    }
}
