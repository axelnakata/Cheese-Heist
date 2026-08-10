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

    @MainActor
    static func make(type: GearType, role: GearRole) -> GearTwin? {
        guard let mesh = GearMeshFactory.entity(for: type) else { return nil }

        apply(HolographicGearMaterial.make(for: role), to: mesh)

        let holder = Entity()
        let spin = Entity()
        spin.addChild(mesh)
        holder.addChild(spin)

        // Toward the camera: the crane frame's +Z points out of the beam's face, so
        // this is the anti-z-fight nudge and nothing else.
        holder.position.z = HolographicGearMaterial.cameraWardOffset

        return GearTwin(holder: holder, spin: spin, type: type)
    }

    /// Re-skins an existing twin when its role changes, so a role swap does not have
    /// to rebuild the mesh — which would drop it for a frame and read as a flicker.
    @MainActor
    static func restyle(_ twin: GearTwin, as role: GearRole) {
        apply(HolographicGearMaterial.make(for: role), to: twin.spin)
    }

    /// The loaded USDZ is a hierarchy, and only some of its entities carry a model.
    private static func apply(_ material: some Material, to entity: Entity) {
        if var model = entity.components[ModelComponent.self] as ModelComponent? {
            model.materials = Array(repeating: material, count: model.materials.count)
            entity.components.set(model)
        }
        for child in entity.children { apply(material, to: child) }
    }
}
