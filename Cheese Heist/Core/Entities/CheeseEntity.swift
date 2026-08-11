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
//  The wedge is authored lying flat: normalised to a 48mm longest edge it measures
//  35mm across (X), 19mm THICK (Y) and 48mm long (Z), tapering from a wide end at −Z to
//  its point at +Z. `BillboardSystem` turns local +Z to the camera, so what the child
//  got was the wedge end-on down its own length — a yellow lozenge with no triangle in
//  it, not recognisable as cheese. The fix is one fixed rotation INSIDE the billboarded
//  container, so the billboard cannot overwrite it. See `presentation`.
//
//  Those three numbers are in RealityKit's axes, AFTER the Z-up→Y-up conversion that
//  `Entity.load` applies to this Blender export. Probe the raw USD instead — with
//  ModelIO, say — and it reads 35 (X) × 48 (Y) × 19 (Z), with Y and Z swapped relative
//  to everything below. Mixing the two frames up is how the pose keeps going wrong.
//

import RealityKit
import simd
import os

/// The cheese in two parts, for the same reason the gear twin is in two.
///
/// `holder` is positioned — by the role layout, and by the physics on every frame of a
/// lift. `facing` is turned to the camera by `BillboardSystem`, sixty times a second.
/// One entity carrying both means two writers on one transform, which is a race the
/// scene loses in ways that look like the prop having a mind of its own.
struct CheeseProp {
    /// Identity until the scene writes it. Never rotated.
    let holder: Entity
    /// Billboarded. Never moved.
    let facing: Entity
}

@MainActor
enum CheeseEntity {

    /// How big the cheese reads on the table, longest edge, in metres.
    ///
    /// Level 1's payload is 10g of physics; this is the number that decides whether it
    /// looks like something a mouse would want. About the width of the 40T gear, which
    /// is the scale reference the child already has in frame.
    static let longestEdge: Float = 0.048

    // ═══ THE POSE IS BUILT FROM AXES, NOT FROM EULER ANGLES. ═══
    //
    // Three attempts at this were composed as `roll · tilt`, and all three came out
    // somewhere other than intended — the wedge stood on its blunt end, then leaned at
    // 50°, then lay down pointing the wrong way. Composed angles are the problem: the
    // second rotation acts in a frame the first one moved, so nothing in the source
    // says where anything ends up, and each fix is a guess checked on a device.
    //
    // The pose below is stated the way it is actually specified — WHERE THE MODEL'S
    // THREE AXES GO, as seen by the child, with +X screen right, +Y up, +Z out of the
    // screen. Read off `Docs/issues-toFIx-lv1/position final cheese.png`:
    //
    //   • The point goes RIGHT, dipped, receding — so the thick end is nearest the
    //     camera and its end face shows.
    //   • The wedge stands tall end UP: model X, the 35mm direction, is the vertical one.
    //   • The whole thing pitches about its own length, so the top face and its holes
    //     are visible rather than the wedge being seen edge-on.
    //
    // ═══ AND THE POINT IS DIPPED BY THE WEDGE'S OWN TAPER. ═══
    //
    // This is the part that was missing, and the reason the cheese read as standing on
    // its back edge with all three axes already correct. The model is a SYMMETRIC slice:
    // ±17.66mm across at −Z and ±3.51mm at +Z, tapering evenly about the centreline. It
    // is an isoceles wedge, not a slice with one flat side — so with the length held
    // level it balances on its point, both edges rising away from it.
    //
    // Neither `facePitch` nor `apexYaw` can fix that: those turn the wedge about the
    // length and about the vertical, and this needs a turn IN the picture plane.
    // `apexDroop` is that turn, and its angle is not a taste question.

    /// How far round the point recedes from the picture plane. Enough to show the thick
    /// end's face, not so much that the big holed face turns away.
    private static let apexYaw: Float = 0.35

    /// The wedge's underside, rising from the thick end's bottom corner to the point:
    /// atan(14.15 / 48) on the measured mesh. Dipping the point by exactly this much is
    /// what lays that edge flat.
    static let taperHalfAngle: Float = 0.287

    /// …so the point sits below level by precisely the taper. Level would balance the
    /// wedge on its point; less would tip it back onto its heel.
    private static let apexDroop: Float = taperHalfAngle

    /// Pitch about the length: the top leans away, so the child looks down onto the top
    /// face and its holes. This is what carries the wedge's THICKNESS — zero would be a
    /// flat elevation, which reads as a paper triangle rather than a slice.
    private static let facePitch: Float = 0.40

    static func make() -> CheeseProp? {
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
        // goes UNDER the billboarded entity rather than on it — a billboard overwrites
        // orientation every frame, and would take this with it.
        normalised.orientation = presentation

        let facing = Entity()
        facing.addChild(normalised)

        let holder = Entity()
        holder.addChild(facing)
        return CheeseProp(holder: holder, facing: facing)
    }

    /// The pose, as a rotation taking the model's axes to the ones above.
    ///
    /// Built as a basis rather than composed: the columns ARE the images of local X, Y
    /// and Z, so what the code says and what the child sees are the same statement.
    static var presentation: simd_quatf {
        let apex = apexDirection

        // The wedge's tall direction, as close to straight up as being perpendicular to
        // the length allows. Gram-Schmidt rather than a fourth angle to tune — and note
        // that because the length is DIPPED, this comes out tilted by the same taper,
        // which is the whole point: it is the wedge that levels, not the axis.
        let up = simd_float3(0, 1, 0)
        let width = simd_normalize(up - apex * simd_dot(apex, up))

        // Right-handed by construction: width × normal == apex, which is what makes the
        // basis a rotation and not a reflection.
        let normal = simd_cross(apex, width)

        // Columns are the images of model X, Y and Z in that order.
        let pitch = simd_quatf(angle: facePitch, axis: apex)
        return simd_quatf(simd_float3x3(pitch.act(width), pitch.act(normal), apex))
    }

    /// Where the point ends up, in the child's view.
    static var apexDirection: simd_float3 {
        simd_float3(
            cos(apexDroop) * cos(apexYaw),
            -sin(apexDroop),
            -cos(apexDroop) * sin(apexYaw)
        )
    }

    /// Which way the wedge tapers, in the model's own axes: it is widest at −Z and comes
    /// to its point at +Z. Published so the orientation test can check where the point
    /// ends up rather than restating this and agreeing with itself.
    static let apexAxis = simd_float3(0, 0, 1)

    /// The big holed face's normal, in the model's own axes — the thin direction, 19mm
    /// of the 48. This is the face the child has to be looking at.
    static let faceAxis = simd_float3(0, 1, 0)

    /// The wedge's tall direction, in the model's own axes: 35mm at the thick end,
    /// tapering to 7mm at the point.
    static let widthAxis = simd_float3(1, 0, 0)

    /// The underside's cut edge, in the model's own axes — from the thick end's bottom
    /// corner up to the point. THIS is the edge the cheese rests on, and the pose is
    /// correct exactly when it comes out horizontal.
    static var restingEdgeAxis: simd_float3 {
        simd_float3(sin(taperHalfAngle), 0, cos(taperHalfAngle))
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
