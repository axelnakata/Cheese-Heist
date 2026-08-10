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
//  ═══ AND IT IS TURNED BEFORE IT IS SHOWN. ═══
//
//  The wedge is authored lying flat: measured in RealityKit's axes it is 0.876 wide,
//  0.482 THICK (Y) and 1.190 long (Z), tapering from a wide base at +Z to an apex at
//  −Z. `BillboardSystem` turns local +Z to the camera, so what the child got was the
//  wedge end-on down its own length — a yellow lozenge with no triangle in it, which is
//  not recognisable as cheese. The fix is one fixed rotation INSIDE the billboarded
//  container: bring the flat triangular face round to the camera and drop the apex to
//  the lower left, which is how the cheese is drawn in every Level 1 frame.
//

import RealityKit
import simd
import os

@MainActor
enum CheeseEntity {

    /// How big the cheese reads on the table, longest edge, in metres.
    ///
    /// Level 1's payload is 10g of physics; this is the number that decides whether it
    /// looks like something a mouse would want. About the width of the 40T gear, which
    /// is the scale reference the child already has in frame.
    static let longestEdge: Float = 0.048

    /// How far the flat face is turned from square-on to the camera.
    ///
    /// Not zero: a face exactly perpendicular to the view has no thickness in it and
    /// reads as a paper triangle. Twelve degrees is enough to see the rind.
    private static let faceTilt: Float = .pi / 2 - 0.21

    /// Roll about the view axis. Puts the apex down and to the left, tail-of-the-wedge
    /// toward the mouse, matching the Level 1 frames.
    private static let apexRoll: Float = .pi - 0.35

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

        // The normaliser's container is ours to write, and the presentation rotation
        // goes on it rather than on what we hand back — because what we hand back is
        // billboarded, and a billboard overwrites orientation every frame.
        normalised.orientation = presentation

        let holder = Entity()
        holder.addChild(normalised)
        return holder
    }

    /// Flat face to the camera, apex down-left.
    private static var presentation: simd_quatf {
        simd_quatf(angle: apexRoll, axis: simd_float3(0, 0, 1))
            * simd_quatf(angle: faceTilt, axis: simd_float3(1, 0, 0))
    }

    /// How far above its own origin the cheese's underside sits, in metres.
    ///
    /// The cheese RESTS on the table, and its origin is its centre — so placing the
    /// origin at table height buries half of it. That was survivable at 32mm and is not
    /// at 48mm. Measured rather than assumed, because the presentation rotation decides
    /// which of the wedge's three very different dimensions is now the vertical one.
    static func restingLift(of cheese: Entity) -> Float {
        (ModelBounds.measure(cheese)?.extents.y ?? 0) / 2
    }
}
