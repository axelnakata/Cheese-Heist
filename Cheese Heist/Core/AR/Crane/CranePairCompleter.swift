//
//  CranePairCompleter.swift
//  Cheese Heist
//
//  Where the unmeasured gear must be, given the measured one and the distance LEGO
//  fixes between them.
//
//  THIS IS THE NORMAL CASE AT ARM'S LENGTH, NOT A RARE DEGRADATION. A 40T gear covers
//  hundreds of depth pixels at 50cm while an 8T covers about seven, so past roughly
//  40cm one gear always reads and one never does. Without this the facing direction
//  would freeze at whatever angle the child first stood at and never improve.
//
//  NOTE WHICH QUANTITY THIS RECOVERS, because the same 24mm number was previously used
//  for something it was badly suited to. Asking LEGO's spacing for the crane's
//  DISTANCE meant using a 24mm ruler to measure 300mm, and it amplified a pixel of box
//  noise roughly twelvefold — that was the original alignment bug. Distance now comes
//  from LiDAR. The spacing is asked only for an ANGLE, measured across its own length,
//  where a pixel of box noise is about a degree and averages away.
//
//  PURE ON PURPOSE. The mirror-image ambiguity below is disambiguated by the running
//  orientation estimate, which arrives as the `preferredNormal` PARAMETER rather than
//  through a reference back to `CraneOrientationTracker`. That keeps the subtlest
//  maths in the whole port testable against synthetic geometry.
//

import simd

enum CranePairCompleter {

    /// The unmeasured gear's world position, or nil if this frame cannot place it.
    ///
    /// It lies somewhere on its own camera ray, and exactly `centreDistance` from the
    /// gear that was measured — a ray against a sphere, with a closed form.
    static func complete(
        from measured: simd_float3,
        along ray: CameraRay,
        centreDistance: Float,
        camera: simd_float3,
        preferredNormal: simd_float3?
    ) -> simd_float3? {
        guard centreDistance > 1e-4 else { return nil }

        let toMeasured = measured - ray.origin
        let closest = simd_dot(ray.direction, toMeasured)
        guard closest > 0 else { return nil }        // it would be behind the camera

        let gap = simd_length_squared(toMeasured) - centreDistance * centreDistance
        let discriminant = closest * closest - gap

        // A ray that misses the sphere entirely means the boxes disagree with LEGO's
        // geometry by more than the geometry allows — a gear boxed a few pixels off.
        // Closest approach is the least-wrong answer available, and it reads as face-on,
        // which is the right way to be wrong when the child is standing in front.
        let root: Float = discriminant > 0 ? sqrt(discriminant) : 0
        let distances: [Float] = [closest - root, closest + root].filter { $0 > 0.02 }
        let candidates: [simd_float3] = distances.map { distance in
            ray.origin + ray.direction * distance
        }

        guard let first = candidates.first else { return nil }
        guard candidates.count == 2, first != candidates[1] else { return first }

        return disambiguate(
            candidates: candidates,
            measured: measured,
            camera: camera,
            preferredNormal: preferredNormal
        )
    }

    /// Two readings of the same geometry: the pair rotated toward the near side, and
    /// the same pair rotated toward the far one. They are mirror images about the view
    /// direction, so the frame alone cannot separate them — but the crane has not
    /// turned round since the last measurement, so the running estimate can.
    private static func disambiguate(
        candidates: [simd_float3],
        measured: simd_float3,
        camera: simd_float3,
        preferredNormal: simd_float3?
    ) -> simd_float3? {
        if let preferredNormal {
            let scored = candidates.compactMap { candidate -> (simd_float3, Float)? in
                guard let normal = HorizontalNormalSolver.normal(
                    from: [measured, candidate], toward: camera
                ) else { return nil }
                return (candidate, simd_dot(normal, preferredNormal))
            }
            if let best = scored.max(by: { $0.1 < $1.1 }) { return best.0 }
        }

        // Nothing to go on yet — the first frame. Prefer the more face-on reading,
        // which is what the child was asked to stand for.
        let view = simd_normalize(measured - camera)
        return candidates.min {
            abs(simd_dot($0 - measured, view)) < abs(simd_dot($1 - measured, view))
        }
    }
}
