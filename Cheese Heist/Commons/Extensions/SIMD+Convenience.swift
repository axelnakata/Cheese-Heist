// SIMD+Convenience.swift — Cheese Heist
// Common SIMD helpers used across the AR pipeline.

import simd

extension simd_float3 {
    /// Horizontal projection (XZ plane, Y = 0).
    var horizontal: simd_float3 {
        simd_float3(x, 0, z)
    }

    /// Horizontal length, ignoring Y.
    var horizontalLength: Float {
        simd_length(horizontal)
    }
}

extension simd_float4x4 {
    /// The translation column as a float3.
    ///
    /// Not named `translation`: RealityKit declares a member of that name on the same
    /// type, and the collision resolves to whichever is visible in the file rather
    /// than to whichever was meant.
    var translationVector: simd_float3 {
        simd_float3(columns.3.x, columns.3.y, columns.3.z)
    }
}
