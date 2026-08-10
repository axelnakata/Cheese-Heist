//
//  HolographicGearMaterial.swift
//  Cheese Heist
//
//  The twin's look: an emissive wireframe in the gear's role colour, as drawn in the
//  Level 1 frames — a glowing cyan outline over the driver and an amber one over the
//  follower, rather than the parent PRD §12.6 "PBR tinted 35%".
//
//  A tinted solid gear over a real gear reads as a *replacement* for it, and the child
//  then compares a grey plastic gear against a grey plastic gear. An outline reads as
//  an annotation: the real teeth still show through it, which is what makes "the small
//  one is the driver" legible at a glance.
//
//  TWO ANTI-FLICKER MEASURES SURVIVE THE MATERIAL CHANGE, because they have nothing to
//  do with how the gear is shaded:
//
//  - The twin sits 2mm toward the camera of the real gear. Two coincident surfaces
//    z-fight, and a virtual gear registered to within 5mm of a real one is coincident.
//  - It is exempt from occlusion. RealityKit will happily hide the twin behind the
//    scene mesh reconstruction of the very gear it is drawn on.
//

import RealityKit
import SwiftUI
import UIKit

enum HolographicGearMaterial {

    /// How far toward the camera the twin sits, in metres.
    static let cameraWardOffset: Float = 0.002

    static func make(for role: GearRole) -> UnlitMaterial {
        var material = UnlitMaterial(color: tint(for: role))

        // Wireframe. `UnlitMaterial` ignores scene lighting, which is what makes the
        // outline read as emissive without a light of its own — and the AR session's
        // lighting stays the real gear's business.
        material.triangleFillMode = .lines
        material.faceCulling = .none

        return material
    }

    private static func tint(for role: GearRole) -> UIColor {
        // D-1: driver is blue/cyan, follower is amber/gold. Figma is self-consistent on
        // this across all 14 Level 1 frames; parent PRD §7.2 has them reversed.
        let colour: Color = role == .driver ? AppColor.roleDriver : AppColor.roleFollower
        return UIColor(colour)
    }
}
