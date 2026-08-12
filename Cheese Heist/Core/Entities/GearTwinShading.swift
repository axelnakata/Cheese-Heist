//
//  GearTwinShading.swift
//  Cheese Heist
//
//  Takes the gears down a stop, and only the gears.
//
//  ═══ WHY THE GEARS NEED THIS AND THE CHEESE DOES NOT. ═══
//
//  `SceneLightingRig` fixed the virtual props rendering darker than the real room they
//  sit in, and at the intensity that makes the cheese look right the gears blow out: a
//  40T is moulded in light bluish grey, which is nearly white to begin with, so it
//  clipped to a flat white disc with its axle holes washed away — the twin stopped
//  reading as a gear at all. The 8T, being red, was fine.
//
//  The obvious lever is the wrong one. Turning the key light down dims everything, and
//  the cheese is already where it should be — the problem is not the light in the room,
//  it is that one object in the room is white. So the correction goes on the gear's own
//  material, which is the only thing that distinguishes the two cases.
//
//  ═══ IT SCALES THE PART'S COLOUR, IT DOES NOT REPLACE IT. ═══
//
//  The twins wear the Technic part's own materials on purpose — the red 8T has to stay
//  red. So the existing tint is multiplied down rather than overwritten with a grey,
//  which is the difference between "the same parts, less exposed" and "grey parts".
//  Roughness is nudged up at the same time, because a good part of the clipping is the
//  key light's specular highlight off a smooth moulded surface rather than diffuse.
//

import RealityKit
import UIKit

@MainActor
enum GearTwinShading {

    /// What the part's own brightness is multiplied by. Chosen against a 40T under
    /// `SceneLightingRig.keyIntensity`: enough that the axle holes are readable again,
    /// not so much that the twin goes darker than the real gear behind it.
    static let exposure: CGFloat = 0.6

    /// Smooth plastic under a hard key light throws a highlight that clips on its own,
    /// whatever the base colour is. This is a floor, never a reduction — a part authored
    /// rougher than this keeps its own value.
    static let minimumRoughness: Float = 0.75

    /// Applies the correction to every mesh under `entity`.
    static func dim(_ entity: Entity) {
        if var model = entity.components[ModelComponent.self] {
            model.materials = model.materials.map(dimmed)
            entity.components.set(model)
        }
        for child in entity.children {
            dim(child)
        }
    }

    /// Anything that is not a `PhysicallyBasedMaterial` is left exactly as it is: an
    /// unlit material is not responding to the key light and so is not the problem.
    private static func dimmed(_ material: any RealityKit.Material) -> any RealityKit.Material {
        guard var pbr = material as? PhysicallyBasedMaterial else { return material }
        pbr.baseColor.tint = scaled(pbr.baseColor.tint)
        pbr.roughness.scale = max(pbr.roughness.scale, minimumRoughness)
        return pbr
    }

    /// The same colour, less exposed.
    ///
    /// Scaled in HSB rather than per channel, which is the difference between turning
    /// the light down on the part and mixing black into it: hue and saturation are the
    /// part's identity — the 8T is Technic red and has to stay Technic red — and only
    /// brightness is the thing being complained about. Falls back to the original for
    /// any colour space that will not give up components, rather than guessing.
    private static func scaled(_ colour: UIColor) -> UIColor {
        var hue: CGFloat = 0, saturation: CGFloat = 0, value: CGFloat = 0, alpha: CGFloat = 0
        guard colour.getHue(&hue, saturation: &saturation, brightness: &value, alpha: &alpha)
        else { return colour }

        return UIColor(
            hue: hue, saturation: saturation, brightness: value * exposure, alpha: alpha
        )
    }
}
