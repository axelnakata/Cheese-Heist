//
//  BillboardSystem.swift
//  Cheese Heist
//
//  Keeps registered entities turned to face the camera. The mouse and the cheese are
//  flat sprites, so without this they vanish edge-on the moment the child steps to the
//  side of the crane.
//
//  Driven by `SceneUpdateTicker` rather than by its own subscription: PRD-Level1 §6.1
//  gives the scene exactly one `SceneEvents.Update` subscriber, and billboards run
//  LAST in it so they re-orient against the same frame the overlay was projected from.
//

import RealityKit
import simd

@MainActor
final class BillboardSystem {

    private var entities: [Entity] = []

    func register(_ entity: Entity) {
        entities.append(entity)
    }

    func removeAll() {
        entities.removeAll()
    }

    /// One frame's re-orientation, against the camera's current transform.
    func update(cameraTransform: simd_float4x4) {
        let cameraPosition = cameraTransform.translationVector

        for entity in entities {
            guard let orientation = facing(
                from: entity.position(relativeTo: nil), toward: cameraPosition
            ) else { continue }
            entity.setOrientation(orientation, relativeTo: nil)
        }
    }

    /// Built from WORLD UP rather than from the camera's own up vector, so tilting the
    /// iPad does not tilt the mouse. Returns nil when the camera is on top of the
    /// entity and there is no direction to face.
    private func facing(
        from worldPosition: simd_float3, toward camera: simd_float3
    ) -> simd_quatf? {
        var forward = camera - worldPosition
        let distance = simd_length(forward)
        guard distance > 0.001 else { return nil }
        forward /= distance

        var right = simd_cross(simd_float3(0, 1, 0), forward)
        if simd_length(right) < 0.001 {
            right = simd_float3(1, 0, 0)          // looking straight up or down
        }
        right = simd_normalize(right)

        return simd_quatf(simd_float3x3(right, simd_cross(forward, right), forward))
    }
}
