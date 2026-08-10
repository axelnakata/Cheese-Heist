//
//  LoadedModelSanitiser.swift
//  Cheese Heist
//
//  Throws away everything a downloaded asset carries that is not the prop.
//
//  Every model in this app came out of somebody's authoring scene, and USD faithfully
//  exports the whole scene: `Cheese.usdc` has a camera, two sphere lights and a dome
//  light in it; both gears ship a dome light. None of that is the object.
//
//  LIGHTING AN AR SCENE IS THE SESSION'S JOB. A virtual gear sits on top of a real one
//  and a virtual cheese sits on the child's real table — they have to be lit by the
//  light in the room, or they stop reading as objects in it. An asset's own dome light
//  overrides that with the lighting of a Blender file, and a sphere light left eight
//  metres out of frame throws a highlight from a lamp that is not there.
//
//  It runs before measurement as well as before rendering, which is the load-bearing
//  part: see `ModelBounds`.
//

import RealityKit

enum LoadedModelSanitiser {

    /// Removes every camera and light in the hierarchy, in place.
    static func strip(from entity: Entity) {
        // Snapshotted: `removeFromParent` mutates the collection being walked.
        for child in Array(entity.children) {
            if isAuthoringFurniture(child) {
                child.removeFromParent()
            } else {
                strip(from: child)
            }
        }
    }

    private static func isAuthoringFurniture(_ entity: Entity) -> Bool {
        entity.components.has(PointLightComponent.self)
            || entity.components.has(DirectionalLightComponent.self)
            || entity.components.has(SpotLightComponent.self)
            || entity.components.has(ImageBasedLightComponent.self)
            || entity.components.has(PerspectiveCameraComponent.self)
            || entity.components.has(OrthographicCameraComponent.self)
    }
}
