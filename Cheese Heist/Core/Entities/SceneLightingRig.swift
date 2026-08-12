//
//  SceneLightingRig.swift
//  Cheese Heist
//
//  Two invisible lights that follow the camera, so the gears and the cheese are not
//  rendered in whatever gloom the room happens to be in.
//
//  ═══ WHY THE VIRTUAL PARTS COME OUT DARKER THAN THE REAL ONES. ═══
//
//  RealityKit lights an AR scene from an environment probe estimated off the camera
//  feed, and that estimate is conservative by design: it is trying to make a virtual
//  object sit believably in a real room, and a real room indoors is dim. It works for a
//  prop on a table. It does not work here, because the virtual gear is sitting ON the
//  real gear and the child is being asked to compare them — and the auto-exposed camera
//  image of the real part is always brighter than the physically-lit render of the
//  virtual one. The twin reads as a shadow of the part rather than a copy of it.
//
//  So the scene carries its own key and fill. They are `DirectionalLight`s, which have
//  no position and no visible geometry — nothing renders, the surfaces just get
//  brighter.
//
//  ═══ AND THEY FOLLOW THE CAMERA. ═══
//
//  The rig is registered with `BillboardSystem`, so its local +Z always points at the
//  viewer and the lights hang off that in fixed directions. Pinned to the crane instead,
//  a child who walks round to the other side would be looking at the unlit faces — and
//  the mouse and the cheese are billboards, which always turn their front to the camera
//  and so would always be turning it away from a fixed key light.
//

import RealityKit
import simd

@MainActor
enum SceneLightingRig {

    /// Key light strength, in lux. Chosen against the auto-exposed camera image rather
    /// than against a physical room: the job is to match a virtual grey Technic gear to
    /// the real grey Technic gear a centimetre behind it.
    static let keyIntensity: Float = 3_200

    /// Fill, from the opposite side, at a third of the key — enough to open up the
    /// shadowed face without flattening the form out completely.
    static let fillIntensity: Float = 1_100

    /// How much the environment probe's own contribution is scaled by. Above 1 this
    /// brightens image-based lighting, which is what keeps the parts' own colours from
    /// going flat under two hard lights.
    static let environmentBoost: Float = 1.6

    /// A rig to add to the scene and hand to `BillboardSystem`.
    ///
    /// Both lights are children, so billboarding the parent re-aims the pair together
    /// and neither needs its own per-frame update.
    static func make() -> Entity {
        let rig = Entity()
        rig.addChild(light(intensity: keyIntensity, pitch: -0.5, yaw: -0.4))
        rig.addChild(light(intensity: fillIntensity, pitch: 0.35, yaw: 0.5))
        return rig
    }

    /// One directional light, aimed by pitch and yaw away from the viewer.
    ///
    /// A `DirectionalLight` shines along its own −Z. The rig's +Z faces the camera, so a
    /// child at identity would be a head-on torch — flat, and it erases the teeth. The
    /// key is tilted down and to the right of the viewer's shoulder and the fill comes
    /// back up from the other side.
    private static func light(intensity: Float, pitch: Float, yaw: Float) -> Entity {
        let light = DirectionalLight()
        light.light.intensity = intensity
        light.light.isRealWorldProxy = false
        light.shadow = nil
        light.orientation = simd_quatf(angle: yaw, axis: simd_float3(0, 1, 0))
            * simd_quatf(angle: pitch, axis: simd_float3(1, 0, 0))
        return light
    }
}
