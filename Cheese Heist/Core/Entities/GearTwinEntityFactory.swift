//
//  GearTwinEntityFactory.swift
//  Cheese Heist
//
//  Builds one gear twin: a holder that gets positioned, and a spin child that gets
//  rotated.
//
//  THE SPLIT MATTERS. Rotation is written to the spin entity and position to the
//  holder, so the physics loop never touches a transform that placement owns and the
//  alignment filter never touches one the physics owns. A single entity carrying both
//  means every rotation write also rewrites the position, and the two systems fight
//  over the gear at 60 Hz.
//
//  ═══ THE TWIN WEARS THE PART'S OWN MATERIALS. ═══
//
//  It used to be re-skinned as an emissive wireframe in the gear's role colour — cyan
//  for the driver, amber for the follower — on the argument that an outline reads as an
//  annotation while a solid gear reads as a replacement. On a screen that argument held.
//  Over a real grey gear at arm's length it did not: the wireframe moiréd against the
//  real teeth into an orange scribble that was not legible as a gear at all, and colour
//  the app chose sat on top of the colour LEGO chose.
//
//  So nothing is applied. `gear_8` is Technic red, `gear_24` and `gear_40` are the two
//  greys, and the twin looks like the part it is sitting on because it IS that part.
//  Which gear is the driver is carried by the role label and the highlight ring — by
//  the annotations, which is where an annotation belongs.
//

import RealityKit
import simd

/// One twin's two handles.
struct GearTwin {
    /// Positioned in crane-local space. Never rotated.
    let holder: Entity
    /// Rotated about local +Z. Never moved.
    let spin: Entity
    let type: GearType
}

enum GearTwinEntityFactory {

    /// How far toward the camera the twin sits, in metres.
    ///
    /// Two coincident surfaces z-fight, and a virtual gear registered to within 5mm of
    /// a real one is coincident. Now that the twin is opaque this is doing more work
    /// than it was as a wireframe, not less.
    static let cameraWardOffset: Float = 0.002

    @MainActor
    static func make(type: GearType) -> GearTwin? {
        guard let mesh = GearMeshFactory.entity(for: type) else { return nil }

        let holder = Entity()
        let spin = Entity()
        spin.addChild(mesh)
        holder.addChild(spin)

        // Toward the camera: the crane frame's +Z points out of the beam's face, so
        // this is the anti-z-fight nudge and nothing else.
        holder.position.z = Self.cameraWardOffset

        return GearTwin(holder: holder, spin: spin, type: type)
    }
}
