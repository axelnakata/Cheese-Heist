import RealityKit
import UIKit

@MainActor
final class SurfaceInvalidMarkEntity: Entity, HasModel {

    /// Diameter menyesuaikan radius area yang dibutuhkan (sebanding dengan valid ring).
    private static let radius: Float = SurfaceValidationRules.requiredRadius

    override init() {
        super.init()
        setupModel()
    }

    @UnownedRequired init() {
        fatalError("init() has not been implemented")
    }

    private func setupModel() {
        // Disk tipis agar menempel tepat di atas permukaan horizontal
        let mesh = MeshResource.generateDisk(
            radius: Self.radius,
            count: 36
        )

        var material = UnlitMaterial()
        if let texture = try? TextureResource.load(named: "surface_invalid") {
            material.color = .init(tint: .white, texture: .init(texture))
        } else {
            material.color = .init(tint: .red.withAlphaComponent(0.6))
        }

        // Render dua sisi & transparan
        material.blending = .transparent(opacity: .init(floatLiteral: 0.9))

        self.model = ModelComponent(mesh: mesh, materials: [material])
        
        // Sedikit diangkat dari lantai agar tidak z-fighting dengan tekstur meja
        self.position = [0, 0.002, 0]
    }
}