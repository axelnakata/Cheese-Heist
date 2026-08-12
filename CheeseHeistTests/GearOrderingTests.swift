//
//  GearOrderingTests.swift
//  CheeseHeistTests
//
//  The rule that decides which gear the mouse starts on.
//
//  Worth testing on its own because it is a claim about geometry, not about taste: that
//  the crane frame's local +X is screen right from ANY angle the child can stand at, so
//  "the left gear" can be answered without projecting anything.
//

import Foundation
import Testing
import simd
@testable import Cheese_Heist

@MainActor
struct GearOrderingTests {

    /// A gear at `world`, with the id and tooth count the test wants to recognise it by.
    private static func gear(_ teeth: GearType, at world: simd_float3) -> DetectedGear {
        DetectedGear(type: teeth, confidence: 1, worldPosition: world, axis: simd_float3(0, 0, 1))
    }

    /// Facing the crane down the world -Z axis: screen right is world +X.
    @Test("the gear with the smaller world X is on the left when the crane faces +Z")
    func leftToRightFacingForward() {
        let frame = CraneFrame(origin: .zero, normal: simd_float3(0, 0, 1))
        let left = Self.gear(.eightTooth, at: simd_float3(-0.1, 0, 0))
        let right = Self.gear(.fortyTooth, at: simd_float3(0.1, 0, 0))

        // Fed in the wrong order on purpose — sorting is the whole job.
        let ordered = GearOrdering.leftToRight([right, left], in: frame)

        #expect(ordered.map(\.id) == [left.id, right.id])
    }

    /// Standing on the world +X axis instead, screen right is world -Z. Nothing about
    /// the call changes; the frame carries the difference.
    @Test("left and right follow the crane's facing, not the world axes")
    func leftToRightFromTheSide() {
        let frame = CraneFrame(origin: .zero, normal: simd_float3(1, 0, 0))
        let left = Self.gear(.eightTooth, at: simd_float3(0, 0, 0.1))
        let right = Self.gear(.fortyTooth, at: simd_float3(0, 0, -0.1))

        let ordered = GearOrdering.leftToRight([right, left], in: frame)

        #expect(ordered.map(\.id) == [left.id, right.id])
    }

    /// The ordering is by position, so it must NOT fall back to tooth count — a crane
    /// built with the big gear on the left is a perfectly ordinary crane.
    @Test("a large gear on the left still drives")
    func sizeDoesNotDecide() {
        let frame = CraneFrame(origin: .zero, normal: simd_float3(0, 0, 1))
        let large = Self.gear(.fortyTooth, at: simd_float3(-0.1, 0, 0))
        let small = Self.gear(.eightTooth, at: simd_float3(0.1, 0, 0))

        let ordered = GearOrdering.leftToRight([small, large], in: frame)
        let assignment = Level1SceneDirector.initialAssignment(leftToRight: ordered)

        #expect(assignment?.driverID == large.id)
        #expect(assignment?.followerID == small.id)
    }

    @Test("the teaching run puts the mouse on the left gear and the cheese on the right")
    func initialAssignmentTakesTheLeftGearAsDriver() {
        let frame = CraneFrame(origin: .zero, normal: simd_float3(0, 0, 1))
        let left = Self.gear(.eightTooth, at: simd_float3(-0.1, 0, 0))
        let right = Self.gear(.fortyTooth, at: simd_float3(0.1, 0, 0))

        let ordered = GearOrdering.leftToRight([right, left], in: frame)
        let assignment = Level1SceneDirector.initialAssignment(leftToRight: ordered)

        #expect(assignment?.driverID == left.id)
        #expect(assignment?.followerID == right.id)
    }

    /// One gear is not a pair, and neither is three. The caller shows the manual
    /// fallback rather than guessing.
    @Test("an assignment needs exactly two gears")
    func assignmentNeedsAPair() {
        let single = [Self.gear(.eightTooth, at: .zero)]

        #expect(Level1SceneDirector.initialAssignment(leftToRight: []) == nil)
        #expect(Level1SceneDirector.initialAssignment(leftToRight: single) == nil)
    }
}
