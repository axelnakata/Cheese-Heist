//
//  CranePlaneEstimator.swift
//  Cheese Heist
//
//  Establishes ONE coordinate frame for the whole crane, and keeps it correct from
//  wherever the child is standing RIGHT NOW. One job — answer "which way is the crane
//  facing, and where exactly are its two gears, as seen from here?".
//
//  ORCHESTRATION ONLY. Every piece of maths below lives in its own pure type:
//  `GearDepthProbe` measures, `HorizontalNormalSolver` turns two points into a facing
//  direction, `CranePairCompleter` recovers the gear that was too small to measure,
//  `ApparentSizeCheck` second-guesses the distance, `GearPlane` intersects the rays.
//  The two things that genuinely have to survive a frame are held by
//  `CraneOrientationTracker` and `CranePlaneOffsetTracker`.
//
//  THE ONE RULE THIS FILE KEEPS:
//  The gears are placed on the rays they were seen along, on EVERY frame, at ANY
//  viewing angle. A point on the ray through a pixel projects back to that pixel, so
//  the overlay lands on the real gear by construction and cannot slide off it however
//  far round the crane the child has walked. Positions are re-solved from scratch every
//  frame and never blended in world space: two ray-exact answers from two camera poses
//  blend into one that is exact for neither.
//
//  AND THE ONE THING IT DELIBERATELY DOES NOT DO:
//  LEGO's spacing is never re-imposed on the result. Pushing the pair back to exactly
//  24mm apart would shift both gears off their own rays to satisfy a constraint the
//  distance estimate is already responsible for. If the separation comes out wrong the
//  honest reading is that the distance is wrong — and that is checked where it belongs,
//  rather than papered over here where it would cost the alignment. (Parent PRD §12.4
//  step 6 says to snap; it is the original alignment bug, so it is amended away.)
//
//  WHAT THIS DOES NOT OWN:
//  Holding the scene steady between measurements. That is the ARKit anchor's job, and
//  giving it back is what stops a missed detection from turning the child's own
//  movement into drift. This file measures; it does not carry.
//

import Foundation
import simd

@MainActor
final class CranePlaneEstimator {

    /// Sanity bounds on how far the crane can be, in metres. A child holding an iPad.
    static let minimumRange: Float = 0.12
    static let maximumRange: Float = 2.5

    /// Bounds on (measured gear separation) / (LEGO's known separation).
    ///
    /// Module-1 Technic gears mesh at a centre distance of exactly (t1 + t2) / 2
    /// millimetres, and nothing upstream is ever told that number, so a measurement
    /// landing on it is corroboration rather than circular reasoning. Wide bounds
    /// because this is here to catch an answer out by a factor, not to shave
    /// millimetres.
    static let minimumSeparationAgreement: Float = 0.6
    static let maximumSeparationAgreement: Float = 1.7

    let orientation = CraneOrientationTracker()
    let planeOffset = CranePlaneOffsetTracker()

    var sampleCount: Int { planeOffset.sampleCount }
    var isStable: Bool { planeOffset.isStable }
    var canProduceDegradedResult: Bool { planeOffset.canProduceDegradedResult }

    init() {}

    func reset() {
        orientation.reset()
        planeOffset.reset()
    }

    // MARK: - Tracking

    /// One tracking update from one frame: where the crane is, as seen from here.
    ///
    /// Returns nil only when there is genuinely nothing to place: no orientation
    /// established yet, no distance yet, or rays that do not meet the crane's plane in
    /// front of the camera. A nil is not a problem for the scene — the anchor holds it
    /// — so this can afford to be honest about what it does not know.
    func track(
        detections: [GearDetection], captured: CapturedFrameData
    ) -> CranePlaneSolution? {
        let gears = GearOrdering.ordered(detections)
        guard gears.count == 2 else { return nil }

        let camera = captured.cameraTransform.translationVector
        let rays = gears.map { CameraRayBuilder.ray(throughPixel: $0.centerPixel, captured: captured) }

        let centreDistance = Self.centreDistance(of: gears)

        // Either probe may come back nil, and routinely does: an 8T gear is 10mm across
        // and covers about two depth pixels at arm's length, which is not a measurement.
        // That is fine — the two gears share one plane, so one good reading places both.
        let probes = gears.map {
            GearDepthProbe.measure(box: $0.imageRect, centerPixel: $0.centerPixel, captured: captured)
        }

        guard let normal = facingDirection(
            probes: probes, rays: rays, centreDistance: centreDistance,
            camera: camera, captured: captured
        ) else { return nil }

        if let candidate = offsetCandidate(
            probes: probes, normal: normal, camera: camera,
            gears: gears, captured: captured
        ) {
            planeOffset.adopt(candidate)
        }

        guard let offset = planeOffset.offset else { return nil }

        let plane = GearPlane(point: normal * offset, normal: normal)
        guard let first = plane.intersect(ray: rays[0]),
              let second = plane.intersect(ray: rays[1]) else { return nil }

        return CranePlaneSolution(
            frame: CraneFrame(origin: (first + second) / 2, normal: normal),
            gearPositions: [first, second],
            sampleCount: planeOffset.sampleCount,
            separationAgreement: separationAgreement(probes: probes, centreDistance: centreDistance)
        )
    }

    // MARK: - Orientation

    /// Which way the beam faces, as a horizontal unit vector pointing at the viewer.
    private func facingDirection(
        probes: [GearDepthSample?],
        rays: [CameraRay],
        centreDistance: Float,
        camera: simd_float3,
        captured: CapturedFrameData
    ) -> simd_float3? {
        if let pair = pairPositions(
            probes: probes, rays: rays, centreDistance: centreDistance, camera: camera
        ), HorizontalNormalSolver.hasUsableSpan(pair.0, pair.1),
           let measured = HorizontalNormalSolver.normal(from: [pair.0, pair.1], toward: camera) {
            return orientation.absorb(measured: measured)
        }

        // No usable measurement this frame — neither gear big enough to probe, or the
        // pair stacked vertically so their line has no horizontal component to read. The
        // crane has not moved, so the running estimate is not a fallback: it is still
        // the answer.
        return orientation.heldOrSeeded(cameraTransform: captured.cameraTransform)
    }

    /// Both gear centres in world space, or nil if neither could be measured.
    ///
    /// When both probed, both are used — two independent readings beat one reading and
    /// an assumption, and their disagreement is a check worth having.
    private func pairPositions(
        probes: [GearDepthSample?],
        rays: [CameraRay],
        centreDistance: Float,
        camera: simd_float3
    ) -> (simd_float3, simd_float3)? {
        if let first = probes[0], let second = probes[1] {
            return (first.world, second.world)
        }

        // Whichever gear read, and the ray belonging to the one that did not.
        let index = probes[0] != nil ? 0 : 1
        guard let known = probes[index] else { return nil }
        guard let other = CranePairCompleter.complete(
            from: known.world, along: rays[1 - index], centreDistance: centreDistance,
            camera: camera, preferredNormal: orientation.trackedNormal
        ) else { return nil }

        return index == 0 ? (known.world, other) : (other, known.world)
    }
}
