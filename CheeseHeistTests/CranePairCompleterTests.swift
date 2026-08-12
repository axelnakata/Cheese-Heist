//
//  CranePairCompleterTests.swift
//  CheeseHeistTests
//
//  PRD §12.1 — ray-vs-sphere with synthetic geometry.
//
//  This is the subtlest maths in the whole port, and it is testable at all only because
//  the completer takes `preferredNormal` as a PARAMETER rather than holding a reference
//  back to `CraneOrientationTracker`.
//

import Testing
import simd
@testable import Cheese_Heist

struct CranePairCompleterTests {

    /// A camera at the origin looking down -Z, the way ARKit's is.
    let camera = simd_float3(0, 0, 0)

    /// 24mm — an 8T meshing with a 40T.
    let centreDistance: Float = 0.024

    private func ray(toward point: simd_float3) -> CameraRay {
        CameraRay(origin: camera, direction: simd_normalize(point - camera))
    }

    /// The exact answer: two gears side by side on a beam, 40cm out, facing the camera.
    @Test("a gear on its own ray at the known separation is recovered exactly")
    func recoversTheKnownGear() {
        let measured = simd_float3(-0.012, 0, -0.4)
        let truth = simd_float3(0.012, 0, -0.4)

        let solved = CranePairCompleter.complete(
            from: measured, along: ray(toward: truth), centreDistance: centreDistance,
            camera: camera, preferredNormal: simd_float3(0, 0, 1)
        )

        #expect(solved != nil)
        #expect(simd_distance(solved ?? .zero, truth) < 0.001)
    }

    /// Whatever it returns must sit on the ray it was given — that is the property the
    /// whole overlay leans on.
    @Test("the answer always lies on the supplied ray")
    func answerIsOnTheRay() {
        let measured = simd_float3(-0.012, 0, -0.4)
        let target = ray(toward: simd_float3(0.012, 0.004, -0.39))

        guard let solved = CranePairCompleter.complete(
            from: measured, along: target, centreDistance: centreDistance,
            camera: camera, preferredNormal: nil
        ) else {
            Issue.record("no solution")
            return
        }

        let along = simd_dot(solved - target.origin, target.direction)
        #expect(simd_distance(target.origin + target.direction * along, solved) < 1e-4)
    }

    /// Two mirror-image roots satisfy the geometry — the pair rotated toward the near
    /// side and the same pair rotated toward the far one. The running estimate is what
    /// separates them, and flipping it must flip the answer.
    @Test("the preferred normal disambiguates the two roots")
    func preferredNormalPicksARoot() {
        let measured = simd_float3(-0.010, 0, -0.40)
        let target = ray(toward: simd_float3(0.010, 0, -0.405))

        let near = CranePairCompleter.complete(
            from: measured, along: target, centreDistance: centreDistance,
            camera: camera, preferredNormal: simd_float3(0, 0, 1)
        )
        let far = CranePairCompleter.complete(
            from: measured, along: target, centreDistance: centreDistance,
            camera: camera, preferredNormal: simd_float3(0, 0, -1)
        )

        #expect(near != nil)
        #expect(far != nil)
        #expect(near != far)
    }

    /// A ray that misses the sphere means the boxes disagree with LEGO's geometry by
    /// more than the geometry allows. Closest approach is the least-wrong answer, and
    /// returning nothing would freeze the facing direction instead.
    @Test("a ray that misses the sphere still returns closest approach")
    func missingRayFallsBackToClosestApproach() {
        let measured = simd_float3(0, 0, -0.4)
        let target = ray(toward: simd_float3(0.5, 0, -0.4))   // far outside 24mm

        #expect(CranePairCompleter.complete(
            from: measured, along: target, centreDistance: centreDistance,
            camera: camera, preferredNormal: nil
        ) != nil)
    }

    @Test("a gear behind the camera is refused")
    func behindTheCameraIsRefused() {
        let measured = simd_float3(0, 0, 0.4)      // behind
        let target = CameraRay(origin: camera, direction: simd_float3(0, 0, -1))

        #expect(CranePairCompleter.complete(
            from: measured, along: target, centreDistance: centreDistance,
            camera: camera, preferredNormal: nil
        ) == nil)
    }

    @Test("a degenerate separation is refused")
    func zeroSeparationIsRefused() {
        #expect(CranePairCompleter.complete(
            from: simd_float3(0, 0, -0.4),
            along: ray(toward: simd_float3(0.01, 0, -0.4)),
            centreDistance: 0, camera: camera, preferredNormal: nil
        ) == nil)
    }
}
