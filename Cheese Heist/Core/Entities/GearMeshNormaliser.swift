//
//  GearMeshNormaliser.swift
//  Cheese Heist
//
//  Measures a loaded model and corrects its scale, origin and axis. Nothing about a
//  downloaded asset is taken on faith, because the alignment work rests on the virtual
//  gear being exactly the size of the real one and turning about exactly the right
//  axis, and an exported asset gets all three wrong in ways that are easy to miss:
//
//  - SCALE. CAD tools work in millimetres, USD assumes metres, and LEGO libraries
//    often use LDraw units (1 LDU = 0.4mm). A gear can arrive 1000x too big.
//  - ORIGIN. Exports frequently sit on a corner or an arbitrary datum rather than the
//    axle centre, which would swing the gear around the axis instead of spinning it
//    in place.
//  - AXIS. The scene expects the gear flat in XY turning about +Z. CAD models are
//    commonly Z-up or Y-up, so the gear would stand on edge.
//
//  Measured rather than configured, so a replacement asset needs no code change — and
//  so the same code straightens out the cheese (R-L3) rather than a hand-tuned scale
//  constant being bolted on beside it.
//
//  ═══ NORMALISE ON A WRAPPER — NEVER BY WRITING TO THE MODEL. ═══
//
//  Assigning `model.transform` here is destructive, and destroys exactly the thing the
//  measurement depends on. The importer puts the USD stage's own conventions on the
//  loaded root, and ours declares `upAxis = "Z"`, so the root carries the rotation that
//  turns the file's Z-up world into RealityKit's Y-up one. Overwriting the root threw
//  that away, which laid every gear flat: the axle pointed at the ceiling instead of
//  out of the beam, and spinning it about the beam's normal swung the whole disc
//  around the axle hole rather than turning it. The recentring went with it —
//  `bounds.center` was measured in a frame the assignment had just deleted, so each
//  gear was displaced by its own bounding box's offset, in its own direction.
//
//  The wrapper's transform COMPOSES with the model's instead of replacing it, and its
//  child space is precisely the frame `bounds` was measured in, so the correction lands
//  where it was calculated. Entity transforms compose as translate * rotate * scale, so
//  the offset bringing the model's centre to the origin has to be rotated and scaled
//  too.
//

import RealityKit
import simd

enum GearMeshNormaliser {

    /// A flat disc: recentred, turned so its axle runs along +Z, and scaled until it
    /// measures `targetDiameter` across.
    ///
    /// A spur gear is a flat disc, so its thinnest dimension is the axle axis and the
    /// widest of the other two is its diameter. That holds whatever the model was
    /// exported from, which is why the axis needs no per-asset configuration.
    static func normalisedDisc(_ model: Entity, targetDiameter: Float) -> Entity? {
        guard let extents = measuredExtents(of: model) else { return nil }

        var axisIndex = 0
        if extents.value[1] < extents.value[axisIndex] { axisIndex = 1 }
        if extents.value[2] < extents.value[axisIndex] { axisIndex = 2 }

        var axis = simd_float3.zero
        axis[axisIndex] = 1

        let planar = (0..<3).filter { $0 != axisIndex }.map { extents.value[$0] }
        let measuredDiameter = max(planar[0], planar[1])
        guard measuredDiameter > 0 else { return nil }

        return wrap(
            model,
            centre: extents.centre,
            rotation: rotation(from: axis, to: simd_float3(0, 0, 1)),
            scale: targetDiameter / measuredDiameter
        )
    }

    /// A prop with no meaningful axis: recentred and scaled so its longest edge
    /// measures `targetLongestEdge`. Orientation is left exactly as authored.
    static func normalisedProp(_ model: Entity, targetLongestEdge: Float) -> Entity? {
        guard let extents = measuredExtents(of: model) else { return nil }

        let longest = max(extents.value[0], max(extents.value[1], extents.value[2]))
        guard longest > 0 else { return nil }

        return wrap(
            model,
            centre: extents.centre,
            rotation: simd_quatf(angle: 0, axis: simd_float3(0, 0, 1)),
            scale: targetLongestEdge / longest
        )
    }

    // MARK: - Measurement

    /// Measured BEFORE reparenting, so this is world space — and world space for an
    /// entity with no parent means the model's own transform IS the frame these
    /// numbers are in. That is what the wrapper below relies on.
    private static func measuredExtents(
        of model: Entity
    ) -> (value: simd_float3, centre: simd_float3)? {
        let bounds = model.visualBounds(relativeTo: nil)
        let extents = bounds.extents
        guard extents.min() > 0 else { return nil }
        return (extents, bounds.center)
    }

    private static func wrap(
        _ model: Entity, centre: simd_float3, rotation: simd_quatf, scale: Float
    ) -> Entity {
        let holder = Entity()
        holder.addChild(model)
        holder.transform = Transform(
            scale: simd_float3(repeating: scale),
            rotation: rotation,
            translation: -scale * rotation.act(centre)
        )
        return holder
    }

    // MARK: - Geometry

    /// Rotation taking `from` onto `to`, safe at the antiparallel singularity where
    /// `simd_quatf(from:to:)` is undefined and can return NaN — which would drop the
    /// entity from the scene entirely rather than merely misplace it.
    static func rotation(from: simd_float3, to: simd_float3) -> simd_quatf {
        let start = simd_normalize(from)
        let end = simd_normalize(to)
        let alignment = simd_dot(start, end)

        if alignment > 0.9999 { return simd_quatf(angle: 0, axis: simd_float3(0, 0, 1)) }
        if alignment < -0.9999 {
            let perpendicular = abs(start.x) < 0.9
                ? simd_normalize(simd_cross(start, simd_float3(1, 0, 0)))
                : simd_normalize(simd_cross(start, simd_float3(0, 1, 0)))
            return simd_quatf(angle: .pi, axis: perpendicular)
        }
        return simd_quatf(from: start, to: end)
    }
}
