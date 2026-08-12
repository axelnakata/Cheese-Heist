//
//  PlaneGeometryProbe.swift
//  Cheese Heist
//
//  The ARKit half of surface detection: fire a ray at the middle of the screen, work out
//  which detected plane it landed on, and measure how much of that plane surrounds it.
//
//  Split out of `PlaneDetectionService` so the service is only debounce and state, and
//  so all the ARKit geometry sits in one place next to `SurfaceValidationRules`, which
//  is its pure counterpart.
//
//  ═══ THE RAYCAST CASCADES. ═══
//
//  `.existingPlaneGeometry` is the strictest target: the ray has to land inside a
//  plane's detected polygon, which on a plain white table can take several seconds to
//  fill in. Asking only for that meant the very first version reported "no surface"
//  while pointing straight at a table. So it falls back to `.existingPlaneInfinite`
//  (the plane's mathematical extension) and then to `.estimatedPlane`.
//
//  The plane anchor is then resolved SEPARATELY from the hit, because the permissive
//  targets return a result with no anchor attached. Without that, `result.anchor` came
//  back nil, the extent read as zero, and every surface was "too small".
//

import ARKit
import RealityKit
import simd

struct PlaneProbeResult {
    let worldTransform: simd_float4x4
    let distance: Float
    /// `nil` when the ray hit an estimated plane with no anchor behind it yet.
    let clearance: Float?
}

enum PlaneGeometryProbe {

    private static let targets: [ARRaycastQuery.Target] = [
        .existingPlaneGeometry, .existingPlaneInfinite, .estimatedPlane
    ]

    static func probe(arView: ARView) -> PlaneProbeResult? {
        let centre = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        guard centre.x > 0, centre.y > 0 else { return nil }

        guard let result = firstHit(arView: arView, at: centre) else { return nil }

        let hit = result.worldTransform.columns.3
        let point = simd_float3(hit.x, hit.y, hit.z)
        let distance = simd_length(point - arView.cameraTransform.translation)

        return PlaneProbeResult(
            worldTransform: result.worldTransform,
            distance: distance,
            clearance: clearance(at: point, result: result, session: arView.session)
        )
    }

    private static func firstHit(arView: ARView, at centre: CGPoint) -> ARRaycastResult? {
        for target in targets {
            guard let query = arView.makeRaycastQuery(
                from: centre, allowing: target, alignment: .horizontal
            ) else { continue }
            if let hit = arView.session.raycast(query).first { return hit }
        }
        return nil
    }

    // MARK: - Clearance

    /// The largest clearance offered by any horizontal plane containing the hit.
    ///
    /// The raycast's own anchor is preferred, but the permissive targets return none —
    /// so the session's plane anchors are searched and the most generous match wins.
    /// `nil` means no plane anchor covers this point at all, which is a different
    /// answer from "a plane covers it but is too small".
    private static func clearance(
        at point: simd_float3, result: ARRaycastResult, session: ARSession
    ) -> Float? {
        if let anchor = result.anchor as? ARPlaneAnchor {
            return clearance(at: point, on: anchor)
        }

        let planes = (session.currentFrame?.anchors ?? [])
            .compactMap { $0 as? ARPlaneAnchor }
            .filter { $0.alignment == .horizontal }

        let measured = planes.compactMap { clearance(at: point, on: $0) }
        return measured.max()
    }

    /// How far the point sits from the nearest edge of this plane's extent rectangle.
    ///
    /// Returns a negative value when the point lies outside the rectangle, which the
    /// `max()` above then discards in favour of a plane that does contain it.
    private static func clearance(at point: simd_float3, on plane: ARPlaneAnchor) -> Float? {
        let local = simd_inverse(plane.transform) * simd_float4(point, 1)
        guard local.w != 0 else { return nil }

        // Offset from the plane's centre, in the plane's own frame.
        let offset = simd_float2(local.x - plane.center.x, local.z - plane.center.z)

        // The extent rectangle can be rotated about Y relative to the anchor, so the
        // offset is rotated back into the rectangle's frame before it is compared.
        let angle = -plane.planeExtent.rotationOnYAxis
        let rotated = simd_float2(
            offset.x * cos(angle) - offset.y * sin(angle),
            offset.x * sin(angle) + offset.y * cos(angle)
        )

        let halfExtent = simd_float2(plane.planeExtent.width / 2, plane.planeExtent.height / 2)
        return SurfaceValidationRules.clearance(halfExtent: halfExtent, offset: rotated)
    }
}
