// CranePose.swift — Cheese Heist
// Model: origin + heading for a gravity-aligned crane.

import simd

struct CranePose: Equatable, Sendable {
    let origin: simd_float3
    let heading: Float

    static let identity = CranePose(origin: .zero, heading: 0)
}
