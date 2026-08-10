//
//  CranePlaneEstimator+Distance.swift
//  Cheese Heist
//
//  The distance half of the solve: this frame's opinion on how far away the crane's
//  plane is, and the two independent checks it has to survive first.
//

import Foundation
import simd

extension CranePlaneEstimator {

    /// This frame's opinion on how far away the crane's plane is.
    ///
    /// Nil means the frame has no opinion worth having — a normal outcome, not a
    /// failure. The tracked value stands, the gears are still placed on this frame's
    /// rays, and nothing on screen moves as a result.
    func offsetCandidate(
        probes: [GearDepthSample?],
        normal: simd_float3,
        camera: simd_float3,
        gears: [GearDetection],
        captured: CapturedFrameData
    ) -> Float? {
        guard let value = measuredOffset(
            probes: probes, normal: normal,
            centreDistance: Self.centreDistance(of: gears)
        ) else { return nil }

        // Sanity: a child holding an iPad.
        let range = simd_dot(normal, camera) - value
        guard range > Self.minimumRange, range < Self.maximumRange else { return nil }

        let larger = gears[0].toothCount >= gears[1].toothCount ? 0 : 1
        guard ApparentSizeCheck.accepts(
            measuredRange: range,
            largestGearTeeth: gears[larger].toothCount,
            box: gears[larger].imageRect,
            intrinsics: captured.cameraIntrinsics
        ) else { return nil }

        return value
    }

    func measuredOffset(
        probes: [GearDepthSample?], normal: simd_float3, centreDistance: Float
    ) -> Float? {
        // Both gears measured: use their midpoint, which averages down the noise in
        // each and is also where the frame's origin will land.
        if let first = probes[0], let second = probes[1] {
            // If the two disagree about how far apart they are, one of them found
            // something that is not a gear. Neither is then usable.
            guard let agreement = separationAgreement(probes: probes, centreDistance: centreDistance),
                  agreement > Self.minimumSeparationAgreement,
                  agreement < Self.maximumSeparationAgreement else { return nil }
            return simd_dot(normal, (first.world + second.world) / 2)
        }

        // One gear only — normally the larger. The two share a plane, so this places
        // both; the smaller one falls out as a ray/plane hit at the call site.
        guard let single = probes.compactMap({ $0 }).first else { return nil }
        return simd_dot(normal, single.world)
    }

    /// LEGO module 1: the meshing centre distance in millimetres is the tooth sum
    /// halved — 24mm for an 8T against a 40T. Nothing upstream is ever told this
    /// number, which is what makes a measurement landing on it corroboration rather
    /// than circular reasoning.
    static func centreDistance(of gears: [GearDetection]) -> Float {
        guard gears.count == 2 else { return 0 }
        return GearGeometry.centreDistance(gears[0].toothCount, gears[1].toothCount)
    }

    /// Measured gear separation over LEGO's known separation, when both gears probed.
    func separationAgreement(
        probes: [GearDepthSample?], centreDistance: Float
    ) -> Float? {
        guard let first = probes[0], let second = probes[1],
              centreDistance > 1e-5 else { return nil }
        return simd_distance(first.world, second.world) / centreDistance
    }
}
