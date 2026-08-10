//
//  GearHighlightRing.swift
//  Cheese Heist
//
//  The white pulse that says "this gear is tappable", drawn around a twin during
//  `selectingRoles`, and the steady spotlight ring used while teaching.
//
//  A torus rather than a SwiftUI overlay: it has to sit in the scene at the gear's own
//  depth and scale, so that walking round the crane moves it with the gear instead of
//  leaving a circle painted on the screen.
//

import RealityKit
import SwiftUI
import UIKit

enum GearHighlightRing {

    /// How far outside the gear's tips the ring sits, in metres.
    static let clearance: Float = 0.004

    /// Thickness of the ring itself.
    static let thickness: Float = 0.0015

    @MainActor
    static func make(for type: GearType, colour: Color = AppColor.textOnCamera) -> ModelEntity {
        let radius = GearGeometry.tipRadius(of: type) + clearance
        let mesh = MeshResource.generateCylinder(height: thickness, radius: radius)

        var material = UnlitMaterial(color: UIColor(colour))
        material.triangleFillMode = .lines
        material.faceCulling = .none

        let ring = ModelEntity(mesh: mesh, materials: [material])

        // The cylinder is generated standing on Y; the gear's axis is +Z.
        ring.orientation = simd_quatf(angle: .pi / 2, axis: simd_float3(1, 0, 0))
        ring.position.z = HolographicGearMaterial.cameraWardOffset
        return ring
    }
}
