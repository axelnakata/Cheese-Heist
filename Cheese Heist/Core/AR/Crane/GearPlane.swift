//
//  GearPlane.swift
//  Cheese Heist
//
//  The plane both gears lie in, and where a camera ray crosses it.
//
//  This is how gear positions are obtained rather than by reading depth at each
//  gear's centre pixel: a point on the ray through a pixel projects back to that
//  pixel by construction, so the overlay lands on the real gear whatever angle it is
//  seen from, and it does so on every frame rather than being remembered.
//

import simd

struct GearPlane: Equatable, Sendable {
    let point: simd_float3
    let normal: simd_float3

    func intersect(ray: CameraRay) -> simd_float3? {
        let denominator = simd_dot(ray.direction, normal)
        guard abs(denominator) > 1e-6 else { return nil }   // ray parallel to plane

        let distance = simd_dot(point - ray.origin, normal) / denominator
        guard distance > 0.02, distance < 5 else { return nil }  // behind camera, or absurd

        return ray.origin + ray.direction * distance
    }
}
