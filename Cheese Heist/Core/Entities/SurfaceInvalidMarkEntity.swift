//
//  SurfaceInvalidMarkEntity.swift
//  Cheese Heist
//
//  PRD-Cutscene §7.4 — the red ✗ shown at the raycast hit when the surface is not valid.
//  Read off Figma `cutscene guidelines - Fall Back` (522:208), node 977:131 ("Group 29"):
//  two 396.139 × 83 rounded bars rotated ±45°, each doubled with a darker copy offset
//  down-right underneath for a bevelled, "sitting on the surface" look.
//
//  ═══ REAL GEOMETRY, NOT A TEXTURED QUAD — SAME REASON AS THE RING. ═══
//
//  The previous version painted `surface_invalid.png` (an unrelated paint-stroke brush
//  asset, not this design) onto a flat quad. Because it never matched the Figma mark and
//  because `follow()` was only ever called with a hit that existed while the surface was
//  already valid (see `PlaneDetectionService.latestHitTransform`), the quad sat wherever
//  it was last positioned — usually nowhere, since an invalid surface never produced a
//  `hitTransform` to begin with — which read as "doesn't appear" or "floats". Building
//  the ✗ from `generatePlane`, the same primitive `SurfaceRingEntity` uses for a shape
//  that has to lie flush against a tilting plane, makes it a sticker for the same reason
//  the ring already is one: real geometry parented under the raycast hit, not a decal.
//

import RealityKit
import SwiftUI
import UIKit
import simd

@MainActor
enum SurfaceInvalidMarkEntity {

    /// Tip-to-tip footprint, in metres — equal to the ring's outer diameter. The mark is
    /// a promise about the same footprint the ring would have claimed.
    private static let diameter: Float = SurfaceValidationRules.requiredRadius * 2

    /// Bar thickness ÷ bar length, read off the Figma bar (83 / 396.139).
    private static let thicknessRatio: Float = 83.0 / 396.139

    /// Corner radius ÷ thickness, read off the Figma bar (12 / 83).
    private static let cornerRadiusRatio: Float = 12.0 / 83.0

    /// How far the darker "shadow" duplicate sits from the face, as a fraction of
    /// `diameter` — read off the offset between Figma's front and shadow rectangles.
    private static let shadowOffsetRatio: Float = 0.06

    // ponytail: skipped tinting the shadow bars' own thin edge — the offset duplicate
    // alone reads as bevelled at this size; add a third tone only if a design review
    // says otherwise.

    static func make() -> Entity {
        // bounding = (length + thickness) * cos(45°), thickness = length * thicknessRatio
        let length = diameter / ((1 + thicknessRatio) * Float(cos(Double.pi / 4)))
        let thickness = length * thicknessRatio
        let cornerRadius = thickness * cornerRadiusRatio
        let shadowOffset = diameter * shadowOffsetRatio

        let mesh = MeshResource.generatePlane(width: length, depth: thickness, cornerRadius: cornerRadius)

        let holder = Entity()

        let shadow = Entity()
        shadow.position = simd_float3(shadowOffset, 0, shadowOffset)
        holder.addChild(shadow)
        addBars(mesh: mesh, colour: AppColor.surfaceInvalidMarkEdge, to: shadow)

        // Face bars sit a hair above the shadow's so they draw over it without fighting.
        let face = Entity()
        face.position = simd_float3(0, 0.001, 0)
        holder.addChild(face)
        addBars(mesh: mesh, colour: AppColor.surfaceInvalidMark, to: face)

        return holder
    }

    private static func addBars(mesh: MeshResource, colour: Color, to parent: Entity) {
        var material = UnlitMaterial(color: UIColor(colour))
        material.faceCulling = .none

        for angle: Float in [.pi / 4, -.pi / 4] {
            let bar = ModelEntity(mesh: mesh, materials: [material])
            bar.orientation = simd_quatf(angle: angle, axis: simd_float3(0, 1, 0))
            parent.addChild(bar)
        }
    }

    // MARK: - Follow

    /// Moves the mark onto the raycast hit and stands it upright against whatever it
    /// hit — flat on a table, upright and facing outward on a wall.
    ///
    /// Deliberately its own `follow`, not a reuse of `SurfaceRingEntity.follow`: the ring
    /// only ever appears on a horizontal surface, so it can get away with discarding the
    /// hit's rotation outright. This mark also has to stand on walls, where the surface's
    /// own normal is the only orientation information worth keeping — everything else
    /// about `follow` (position from the hit, a distrust of the raycast's own tangent
    /// rotation) still applies, which is why this rebuilds orientation from `worldUp`
    /// instead of taking the hit transform's rotation wholesale.
    static func follow(_ entity: Entity, hit: simd_float4x4) {
        entity.position = simd_float3(hit.columns.3.x, hit.columns.3.y, hit.columns.3.z)
        let normal = simd_float3(hit.columns.1.x, hit.columns.1.y, hit.columns.1.z)
        entity.orientation = orientation(forNormal: normal)
    }

    /// Identity for a horizontal surface (the mark's own +Y-normal mesh needs no
    /// rotation — same result `SurfaceRingEntity.follow` already gives). Otherwise builds
    /// a stand-upright-against-the-surface rotation from the normal alone: `worldUp` is
    /// used as the sole reference for "which way is up on the wall" rather than the
    /// hit's own tangent rotation, which is exactly the "swings with the camera" noise
    /// `SurfaceRingEntity.follow` already distrusts for a table — on a wall that noise
    /// would show up as the ✗ visibly rolling as the camera moves instead of yawing.
    private static func orientation(forNormal normal: simd_float3) -> simd_quatf {
        let worldUp = simd_float3(0, 1, 0)
        guard abs(simd_dot(normal, worldUp)) < 0.9 else {
            return simd_quatf(angle: 0, axis: worldUp)
        }
        let right = simd_normalize(simd_cross(worldUp, normal))
        let up = simd_cross(normal, right)
        return simd_quatf(simd_float3x3(columns: (right, normal, up)))
    }
}
