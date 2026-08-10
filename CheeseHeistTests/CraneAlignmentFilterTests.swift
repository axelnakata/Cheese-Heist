//
//  CraneAlignmentFilterTests.swift
//  CheeseHeistTests
//
//  The mirror-alignment maths, against synthetic pose sequences.
//
//  The five rules in PRD-Level1 §6.5 are each a bug that was already found and fixed on
//  device. These are here so a later "clean-up" reinstates none of them — in particular
//  that a settled filter leaves the transform ALONE, and that the correction is
//  rate-limited per SECOND rather than per frame.
//

import Testing
import simd
@testable import Cheese_Heist

struct CraneAlignmentFilterTests {

    let tuning = CraneAlignmentTuning.standard

    private func frame(x: Float, heading: Float = 0) -> CraneFrame {
        CraneFrame.make(origin: simd_float3(x, 0, 0), heading: heading)
    }

    /// With no measurement yet there is nothing to ease toward, and writing the
    /// transform would stamp the identity over ARKit's own answer.
    @Test("an uncorrected filter writes nothing")
    func idleWritesNothing() {
        let filter = CraneAlignmentFilter()
        #expect(filter.smooth(deltaTime: 1.0 / 60) == nil)
    }

    /// Rule 2. This is the state the scene is in almost all of the time, and leaving the
    /// transform untouched is what lets ARKit's drift correction reach the screen
    /// unmodified.
    @Test("a settled filter stops writing the transform")
    func settledStopsWriting() {
        let filter = CraneAlignmentFilter()
        filter.correct(toward: frame(x: 0), anchorInverse: matrix_identity_float4x4)

        // Run well past convergence.
        for _ in 0..<600 { _ = filter.smooth(deltaTime: 1.0 / 60) }

        #expect(filter.smooth(deltaTime: 1.0 / 60) == nil)
    }

    /// Rule 4. Motion is identical at 60 or 120 fps — the correction takes the time it
    /// takes, not the number of frames it takes.
    @Test("the same elapsed time moves the same distance at any frame rate")
    func rateIndependent() {
        func travelled(frameRate: Double) -> Float {
            let filter = CraneAlignmentFilter()
            filter.correct(toward: frame(x: 0.5), anchorInverse: matrix_identity_float4x4)

            let step = Float(1 / frameRate)
            for _ in 0..<Int(frameRate / 2) { _ = filter.smooth(deltaTime: step) }
            return filter.currentPose.origin.x
        }

        #expect(abs(travelled(frameRate: 60) - travelled(frameRate: 120)) < 1e-3)
    }

    /// A badly wrong measurement can only crawl. Half a second at 0.02 m/s is 10mm, so
    /// a metre of error must not arrive in that time.
    @Test("translation is rate-limited to maximumDrift")
    func driftIsRateLimited() {
        let filter = CraneAlignmentFilter()
        filter.correct(toward: frame(x: 1.0), anchorInverse: matrix_identity_float4x4)

        for _ in 0..<30 { _ = filter.smooth(deltaTime: 1.0 / 60) }

        let travelled = filter.currentPose.origin.x
        #expect(travelled <= tuning.maximumDrift * 0.5 + 1e-4)
        #expect(travelled > 0)
    }

    /// Rule 5. Crossing the +/-pi seam must not swing the scene half a turn.
    ///
    /// The heading rate limit is 6 degrees a second, so settling onto a target near pi
    /// takes about half a minute of simulated time — hence the long warm-up.
    @Test("heading steps the short way round")
    func headingTakesTheShortPath() {
        let filter = CraneAlignmentFilter()
        let step = Float(1.0 / 60)

        filter.correct(
            toward: frame(x: 0, heading: .pi - 0.03), anchorInverse: matrix_identity_float4x4
        )
        for _ in 0..<3_600 { _ = filter.smooth(deltaTime: step) }

        let settled = filter.currentPose.heading
        #expect(abs(settled - (.pi - 0.03)) < 0.01)

        // Three degrees away the SHORT way, across the seam. Lerping the normal vector
        // instead would take the long way and swing the scene through half a turn.
        filter.correct(
            toward: frame(x: 0, heading: -.pi + 0.03), anchorInverse: matrix_identity_float4x4
        )
        _ = filter.smooth(deltaTime: step)

        #expect(filter.currentPose.heading > settled)
    }

    /// A dropped frame or a spell in the background must not licence one huge step.
    @Test("a huge delta time is clamped")
    func deltaTimeIsClamped() {
        let filter = CraneAlignmentFilter()
        filter.correct(toward: frame(x: 1.0), anchorInverse: matrix_identity_float4x4)

        _ = filter.smooth(deltaTime: 30)
        #expect(filter.currentPose.origin.x <= tuning.maximumDrift * 0.1 + 1e-4)
    }

    @Test("reset forgets the correction entirely")
    func resetForgets() {
        let filter = CraneAlignmentFilter()
        filter.correct(toward: frame(x: 0.5), anchorInverse: matrix_identity_float4x4)
        for _ in 0..<60 { _ = filter.smooth(deltaTime: 1.0 / 60) }

        filter.reset()
        #expect(filter.currentPose.origin == .zero)
        #expect(filter.smooth(deltaTime: 1.0 / 60) == nil)
    }
}
