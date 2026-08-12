//
//  SurfaceRingEntity.swift
//  Cheese Heist
//
//  PRD-Cutscene §7.4 — a procedural annulus mesh laid flat on the detected plane.
//
//  Deliberately NOT a textured quad using `ring-yes.svg`: that art is drawn as a
//  pre-squashed perspective ellipse (605 × 451), so laying it flat on the plane would
//  apply perspective twice and read as a flattened oval.
//
//  ═══ THE WINDING IS THE WHOLE BUG. ═══
//
//  The first version emitted `[inner(θ), outer(θ), outer(θ+1)]`, which — with X = cos θ
//  and Z = sin θ in a right-handed Y-up space — produces a face normal of -Y. The front
//  faces pointed at the floor, so looking down at a table (the only way anyone looks at
//  this screen) showed the culled back side and the ring was invisible; where it did
//  come through it read as a dark smear, because the declared vertex normals said +Y
//  while the geometry said -Y.
//
//  So: the winding is reversed here, AND `faceCulling` is set to `.none`. Belt and
//  braces on purpose — a ring that vanishes at a viewing angle is indistinguishable
//  from a ring that was never built, and this one has to be trusted at a glance.
//
//  `UnlitMaterial` and fully opaque, for the same reason `MouseSpriteEntity` is unlit:
//  the ring is a UI affordance drawn into the world, not a lit object. Tinting with a
//  sub-1 alpha while `blending` stays `.opaque` is the other way this renders wrong.
//

import RealityKit
import SwiftUI
import UIKit

@MainActor
enum SurfaceRingEntity {

    /// Outer radius, in metres. Deliberately equal to `CutsceneTuning.orbitRadius` —
    /// the ring is a promise about how much table the cat is about to need, so if the
    /// orbit is retuned and this is not, the ring starts lying.
    static let outerRadius = Float(CutsceneTuning.orbitRadius)

    /// Ring thickness, in metres. Read off `ring-yes.svg`, where the stroke is 40 units
    /// against an ellipse radius of ~279 — about 14 % of the radius.
    private static let thickness: Float = 0.025

    /// How much of the thickness is the darker outer edge.
    private static let edgeFraction: Float = 0.3

    private static let segments = 96

    static func make() -> Entity {
        let holder = Entity()
        let innerEdge = outerRadius - thickness
        let faceOuter = outerRadius - thickness * edgeFraction

        if let face = annulus(from: innerEdge, to: faceOuter) {
            holder.addChild(ModelEntity(mesh: face, materials: [material(AppColor.surfaceRing)]))
        }
        if let edge = annulus(from: faceOuter, to: outerRadius) {
            holder.addChild(
                ModelEntity(mesh: edge, materials: [material(AppColor.surfaceRingEdge)])
            )
        }
        return holder
    }

    /// Moves the ring onto the raycast hit.
    ///
    /// Only the translation is taken. A horizontal-plane raycast's `worldTransform`
    /// carries a yaw that swings with the camera, and a ring that spins as the child
    /// turns their head reads as a compass rather than a target. The mesh is already
    /// flat in XZ, so identity orientation is exactly right.
    static func follow(_ entity: Entity, hit: simd_float4x4) {
        entity.position = simd_float3(hit.columns.3.x, hit.columns.3.y, hit.columns.3.z)
        entity.orientation = simd_quatf(angle: 0, axis: simd_float3(0, 1, 0))
    }

    // MARK: - Mesh

    /// A flat annulus in the XZ plane, wound so its front faces point at +Y.
    private static func annulus(from innerRadius: Float, to outerRadius: Float) -> MeshResource? {
        guard outerRadius > innerRadius, innerRadius >= 0 else { return nil }

        var positions: [simd_float3] = []
        var normals: [simd_float3] = []
        var uvs: [simd_float2] = []
        var indices: [UInt32] = []

        for idx in 0...segments {
            let ratio = Float(idx) / Float(segments)
            let theta = ratio * 2 * .pi
            let unit = simd_float3(cos(theta), 0, sin(theta))

            positions.append(unit * innerRadius)
            normals.append(simd_float3(0, 1, 0))
            uvs.append(simd_float2(ratio, 0))

            positions.append(unit * outerRadius)
            normals.append(simd_float3(0, 1, 0))
            uvs.append(simd_float2(ratio, 1))
        }

        for idx in 0..<segments {
            let base = UInt32(idx * 2)
            // Reversed relative to the first version — these wind so the normal is +Y.
            indices.append(contentsOf: [base, base + 3, base + 1])
            indices.append(contentsOf: [base, base + 2, base + 3])
        }

        var descriptor = MeshDescriptor()
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        descriptor.primitives = .triangles(indices)

        return try? MeshResource.generate(from: [descriptor])
    }

    private static func material(_ colour: Color) -> UnlitMaterial {
        var material = UnlitMaterial(color: UIColor(colour))
        material.faceCulling = .none
        return material
    }
}
