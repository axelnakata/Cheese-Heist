//
//  DetectedGear.swift
//  Cheese Heist
//
//  One gear, resolved to a world position.
//

import Foundation
import simd

struct DetectedGear: Sendable, Identifiable, Equatable {

    /// Carried across tracking updates rather than regenerated.
    ///
    /// The child picks the driver by this id. Minting a fresh one every time the
    /// estimate improves would silently clear their choice mid-flow, so an updated
    /// gear keeps the id of the gear it replaces.
    let id: UUID

    let type: GearType
    let confidence: Float
    let worldPosition: simd_float3

    /// Rotation axis in world space, pointing back toward the camera.
    ///
    /// Both gears share one axis: meshed spur gears turn on parallel axes, and it is
    /// the crane frame's normal, measured off the beam rather than the gear faces.
    let axis: simd_float3

    var toothCount: Int { type.teeth }

    init(
        id: UUID = UUID(),
        type: GearType,
        confidence: Float,
        worldPosition: simd_float3,
        axis: simd_float3
    ) {
        self.id = id
        self.type = type
        self.confidence = confidence
        self.worldPosition = worldPosition
        self.axis = axis
    }
}
