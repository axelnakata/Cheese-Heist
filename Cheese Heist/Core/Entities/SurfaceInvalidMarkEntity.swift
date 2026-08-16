//
//  SurfaceInvalidMarkEntity.swift
//  Cheese Heist
//
//  Created by Naila Lauza on 15/08/26.
//


import RealityKit
import UIKit

@MainActor
final class SurfaceInvalidMarkEntity: Entity, HasModel {

    private static let diameter: Float = SurfaceValidationRules.requiredRadius * 2

    @MainActor
    static func make() -> SurfaceInvalidMarkEntity {
        let entity = SurfaceInvalidMarkEntity()
        entity.setupModel()
        return entity
    }
    
    required override init() {
        super.init()
    }

    private func setupModel() {
        let mesh = MeshResource.generatePlane(
            width: Self.diameter,
            depth: Self.diameter
        )

        var material = UnlitMaterial()
        if let texture = try? TextureResource.load(named: "surface_invalid") {
            material.color = .init(tint: .white, texture: .init(texture))
        } else {
            material.color = .init(tint: UIColor.red.withAlphaComponent(0.6))
        }

        material.blending = .transparent(opacity: .init(floatLiteral: 0.9))

        self.model = ModelComponent(mesh: mesh, materials: [material])
        self.position = [0, 0.002, 0]
    }
}
