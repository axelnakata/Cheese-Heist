//
//  ModelBounds.swift
//  Cheese Heist
//
//  Measures how big the RENDERABLE part of a loaded model is. One job, and it exists
//  because the obvious answer is wrong.
//
//  `Entity.visualBounds(relativeTo:)` is the obvious answer, and it is what the
//  normaliser used to call. The trouble is that a downloaded asset is a whole authoring
//  scene, not a prop: `Cheese.usdc` ships a Blender camera six metres out, two sphere
//  lights eight metres out and a dome light, around a cheese barely a metre across. Any
//  measurement that counts those is measuring the photographer, not the cheese — and it
//  is then fed straight into a division, so the error does not stay small. Scaling a
//  1.2m model by "0.032 / 8.5" leaves a 4mm crumb; missing the scaling entirely leaves a
//  1.2m wall of cheese with the camera inside it, which is what the child actually saw.
//
//  So this counts mesh bounds and nothing else. An entity with no `ModelComponent`
//  contributes only its transform, never its position — a light cannot widen the box it
//  is not in.
//

import RealityKit
import simd

enum ModelBounds {

    /// The union of every mesh under `root`, expressed in the same space
    /// `visualBounds(relativeTo: nil)` would have used — `root`'s own transform included.
    ///
    /// Nil when the hierarchy holds no mesh at all, which is the honest answer for a
    /// file that failed to import: the caller shows no prop rather than a stand-in.
    static func measure(_ root: Entity) -> BoundingBox? {
        accumulate(root, parent: matrix_identity_float4x4)
    }

    private static func accumulate(_ entity: Entity, parent: simd_float4x4) -> BoundingBox? {
        let world = parent * entity.transform.matrix

        var box = entity.components[ModelComponent.self]
            .map { transformed($0.mesh.bounds, by: world) }

        for child in entity.children {
            guard let childBox = accumulate(child, parent: world) else { continue }
            box = box?.union(childBox) ?? childBox
        }

        return box
    }

    /// A box transformed by an arbitrary matrix is the box around its eight transformed
    /// corners. Transforming min and max alone is only correct while the matrix has no
    /// rotation, and every one of these has the importer's Z-up correction in it.
    private static func transformed(_ box: BoundingBox, by matrix: simd_float4x4) -> BoundingBox {
        var lower = simd_float3(repeating: .greatestFiniteMagnitude)
        var upper = simd_float3(repeating: -.greatestFiniteMagnitude)

        for index in 0..<8 {
            let corner = simd_float3(
                index & 1 == 0 ? box.min.x : box.max.x,
                index & 2 == 0 ? box.min.y : box.max.y,
                index & 4 == 0 ? box.min.z : box.max.z
            )
            let point = matrix * simd_float4(corner, 1)
            lower = simd_min(lower, simd_float3(point.x, point.y, point.z))
            upper = simd_max(upper, simd_float3(point.x, point.y, point.z))
        }

        return BoundingBox(min: lower, max: upper)
    }
}
