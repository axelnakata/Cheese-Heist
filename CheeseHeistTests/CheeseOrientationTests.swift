//
//  CheeseOrientationTests.swift
//  CheeseHeistTests
//
//  Where the wedge's three axes end up once it has been turned to face the camera.
//
//  ═══ WHY THIS IS TESTED AND NOT JUST LOOKED AT. ═══
//
//  Four attempts at this pose went out wrong, each of them looking deliberate in the
//  source: the wedge stood on its blunt end, then leaned at 20°, then at 50°, then lay
//  down pointing the wrong way. Composed Euler angles were the reason — the second
//  rotation acts in a frame the first one moved, so reading the code tells you nothing
//  about where the point ends up, and the only check available was a device.
//
//  The fifth was a different mistake, and `restsOnItsUnderside` is here to close it. All
//  three axes were already right and the wedge still read as standing on its back edge,
//  because the model is a SYMMETRIC slice: hold its length level and it balances on its
//  point with both edges rising away. Nothing about where the axes GO catches that —
//  only where the resting EDGE goes does.
//
//  These assert the pose in `Docs/issues-toFIx-lv1/position final cheese.png` as facts
//  about vectors, in the space `BillboardSystem` hands to the camera: +X is screen
//  right, +Y is screen up, +Z is out of the screen.
//

import Foundation
import Testing
import simd
@testable import Cheese_Heist

@MainActor
struct CheeseOrientationTests {

    private static func presented(_ axis: simd_float3) -> simd_float3 {
        CheeseEntity.presentation.act(axis)
    }

    /// The point, the flat cut face's normal, and the wedge's tall direction.
    private static var apex: simd_float3 { presented(CheeseEntity.apexAxis) }
    private static var faceNormal: simd_float3 { presented(CheeseEntity.faceAxis) }
    private static var width: simd_float3 { presented(CheeseEntity.widthAxis) }

    // MARK: - Where the point goes

    /// ═══ THE ONE THAT KEEPS GETTING REVERSED. ═══
    ///
    /// The reference has the wedge tapering to the RIGHT: the notch and the truncated
    /// narrow end are both on the right, the thick end fills the left. A previous build
    /// had it exactly mirrored and it read, in the user's words, as just looking bad.
    @Test("the point faces right")
    func apexFacesRight() {
        #expect(Self.apex.x > 0.8)
    }

    /// The point recedes, which is what turns the thick end towards the child and shows
    /// its end face. Square-on, the wedge reads as a flat cut-out.
    @Test("the point recedes, so the thick end is nearest")
    func apexRecedes() {
        #expect(Self.apex.z < -0.15)
    }

    // MARK: - Which way up it sits

    /// ═══ THE ONE THE FIN BUILD FAILED, WITH EVERY AXIS ALREADY CORRECT. ═══
    ///
    /// The slice rests on a cut edge, and that edge rises 16.4° from the thick end to
    /// the point in the model's own frame. Level the LENGTH and the edge is still 16.4°
    /// off the table; the point has to be dipped by the taper for the underside to come
    /// out flat. This is the assertion that says so, and it is the only one that
    /// distinguishes the shipped pose from the corrected one.
    ///
    /// Not exactly zero, and not meant to be: `facePitch` turns the wedge about its own
    /// length to bring the top face into view, and that lifts the resting edge by a bit
    /// over a degree. The bound is 3.4°, which the corrected pose clears at 1.2° and the
    /// shipped one misses at 12.8°.
    @Test("the wedge rests on its underside, not on its point")
    func restsOnItsUnderside() {
        #expect(abs(Self.presented(CheeseEntity.restingEdgeAxis).y) < 0.06)
    }

    /// …which means the point itself hangs below level by about that same taper. Level
    /// or above is the fin; much past it and the wedge is tipping onto its nose.
    @Test("the point is dipped by roughly the wedge's own taper")
    func apexIsDippedByTheTaper() {
        let dip = -asin(Self.apex.y)
        #expect(dip > CheeseEntity.taperHalfAngle * 0.8)
        #expect(dip < CheeseEntity.taperHalfAngle * 1.2)
    }

    // MARK: - Which faces are visible

    /// The big holed face is the one the child has to see. `BillboardSystem` turns local
    /// +Z to the camera, so "facing the child" is the face normal having most of its
    /// length in +Z.
    @Test("the flat cut face is turned towards the child")
    func faceIsTowardsTheCamera() {
        #expect(Self.faceNormal.z > 0.7)
    }

    /// …and tipped forward far enough that the TOP face and its holes show, which is
    /// what gives the wedge its thickness. A normal with no downward component is a
    /// dead-square elevation: a paper triangle.
    @Test("the wedge is pitched forward, so the top face shows")
    func topFaceIsVisible() {
        #expect(Self.faceNormal.y < -0.2)
    }

    /// Tall end up, which puts the slope of the top running down towards the point. The
    /// wedge upside down is a different — and wrong — shape.
    @Test("the wedge stands tall end up")
    func standsTheRightWayUp() {
        #expect(Self.width.y > 0.7)
    }

    // MARK: - The basis itself

    /// A basis assembled from three vectors is a rotation only if it is orthonormal and
    /// right-handed. Get the handedness wrong and the quaternion conversion returns
    /// something that silently mirrors the model.
    @Test("the pose is a rotation, not a reflection")
    func poseIsAProperRotation() {
        let apex = Self.apex, faceNormal = Self.faceNormal, width = Self.width

        for axis in [apex, faceNormal, width] {
            #expect(abs(simd_length(axis) - 1) < 0.001)
        }
        #expect(abs(simd_dot(apex, faceNormal)) < 0.001)
        #expect(abs(simd_dot(apex, width)) < 0.001)
        #expect(abs(simd_dot(faceNormal, width)) < 0.001)

        // width × normal == apex is the right-handed ordering.
        #expect(simd_length(simd_cross(width, faceNormal) - apex) < 0.001)
    }
}
