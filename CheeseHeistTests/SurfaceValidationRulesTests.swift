//
//  SurfaceValidationRulesTests.swift
//  CheeseHeistTests
//
//  Each threshold boundary for surface validation, both sides — plus the clearance
//  geometry, which is the part that decides whether the cat has room to walk.
//

import Testing
import simd
@testable import Cheese_Heist

struct SurfaceValidationRulesTests {

    private static let comfortable = SurfaceValidationRules.requiredRadius + 0.10

    // MARK: - evaluate

    @Test("valid surface — comfortably within all thresholds")
    func validSurface() {
        #expect(
            SurfaceValidationRules.evaluate(clearance: Self.comfortable, distance: 0.60)
                == .valid
        )
    }

    @Test("too close — just under minimum distance")
    func tooClose() {
        let result = SurfaceValidationRules.evaluate(
            clearance: Self.comfortable,
            distance: SurfaceValidationRules.minimumDistance - 0.01
        )
        #expect(result == .tooClose)
    }

    @Test("too far — just over maximum distance")
    func tooFar() {
        let result = SurfaceValidationRules.evaluate(
            clearance: Self.comfortable,
            distance: SurfaceValidationRules.maximumDistance + 0.01
        )
        #expect(result == .tooFar)
    }

    @Test("too small — clearance just under the required radius")
    func tooSmall() {
        let result = SurfaceValidationRules.evaluate(
            clearance: SurfaceValidationRules.requiredRadius - 0.01, distance: 0.60
        )
        #expect(result == .tooSmall)
    }

    @Test("negative clearance — the hit is off the plane entirely")
    func offPlane() {
        #expect(SurfaceValidationRules.evaluate(clearance: -0.05, distance: 0.60) == .tooSmall)
    }

    @Test("distance takes priority over size")
    func distancePriority() {
        // Both too close AND too small — distance wins, because that is the one the
        // child fixes by moving rather than by finding another table.
        #expect(SurfaceValidationRules.evaluate(clearance: 0.01, distance: 0.10) == .tooClose)
    }

    @Test("exact minimums are accepted, not rejected")
    func exactMinimums() {
        let result = SurfaceValidationRules.evaluate(
            clearance: SurfaceValidationRules.requiredRadius,
            distance: SurfaceValidationRules.minimumDistance
        )
        #expect(result == .valid)
    }

    // MARK: - clearance

    @Test("clearance at the centre of a plane is the smaller half-extent")
    func clearanceAtCentre() {
        let value = SurfaceValidationRules.clearance(
            halfExtent: SIMD2<Float>(0.50, 0.30), offset: SIMD2<Float>(0, 0)
        )
        #expect(value == 0.30)
    }

    @Test("clearance shrinks as the hit moves toward an edge")
    func clearanceOffCentre() {
        let value = SurfaceValidationRules.clearance(
            halfExtent: SIMD2<Float>(0.50, 0.50), offset: SIMD2<Float>(0.40, 0)
        )
        #expect(abs(value - 0.10) < 0.0001)
    }

    @Test("clearance is signed — outside the rectangle it goes negative")
    func clearanceOutside() {
        let value = SurfaceValidationRules.clearance(
            halfExtent: SIMD2<Float>(0.50, 0.50), offset: SIMD2<Float>(0.60, 0)
        )
        #expect(value < 0)
    }

    @Test("a large plane hit near its edge is rejected, not accepted")
    func largePlaneBadHit() {
        // The whole point of measuring clearance instead of extent: this plane is
        // enormous, and the cat would still walk off it.
        let clearance = SurfaceValidationRules.clearance(
            halfExtent: SIMD2<Float>(2.0, 2.0), offset: SIMD2<Float>(1.95, 0)
        )
        #expect(SurfaceValidationRules.evaluate(clearance: clearance, distance: 0.6) == .tooSmall)
    }
}
