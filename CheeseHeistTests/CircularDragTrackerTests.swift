//
//  CircularDragTrackerTests.swift
//  CheeseHeistTests
//
//  PRD §12.1 — clockwise / anticlockwise detection.
//
//  Turning the joystick backwards has to do NOTHING rather than lower the cheese: a
//  child who cranks backwards and sees it descend has learned that the crank controls
//  height directly, which is the opposite of the ratchet the crane actually has.
//

import CoreGraphics
import Foundation
import Testing
@testable import Cheese_Heist

struct CircularDragTrackerTests {

    let centre = CGPoint(x: 100, y: 100)
    let radius: CGFloat = 80

    /// A point `degrees` round the ring in SCREEN space, where y grows downward and so
    /// increasing degrees moves CLOCKWISE — the direction that cranks.
    private func point(atDegrees degrees: Double) -> CGPoint {
        let radians = degrees * .pi / 180
        return CGPoint(
            x: centre.x + radius * cos(radians),
            y: centre.y + radius * sin(radians)
        )
    }

    /// Drags through the given angles, one 60th of a second apart.
    private func drag(through degrees: [Double]) -> CircularDragTracker {
        var tracker = CircularDragTracker()
        for (index, angle) in degrees.enumerated() {
            tracker.update(
                point: point(atDegrees: angle),
                centre: centre,
                timestamp: Double(index) / 60
            )
        }
        return tracker
    }

    @Test("turning clockwise engages the crank")
    func clockwiseEngages() {
        let tracker = drag(through: [0, 10, 20, 30])
        #expect(tracker.engagement == .engaged)
    }

    /// Backwards has to do NOTHING, not lower the cheese — the crane has a ratchet.
    @Test("turning anticlockwise is the wrong way")
    func anticlockwiseIsWrongWay() {
        let tracker = drag(through: [0, -10, -20, -30])
        #expect(tracker.engagement == .wrongWay)
    }

    @Test("resting a finger on the ring is not cranking")
    func restingIsDisengaged() {
        let tracker = drag(through: [0, 0.05, 0.1, 0.15])
        #expect(tracker.engagement == .disengaged)
    }

    /// Crossing due west must not read as most of a turn in the opposite direction.
    @Test("the wrap at 180 degrees is stepped the short way")
    func wrapTakesTheShortPath() {
        // Three degrees clockwise per sample, straight across the +/-180 seam.
        let tracker = drag(through: [174, 177, -180, -177])
        #expect(tracker.engagement == .engaged)
    }

    /// One dropped frame is not the child letting go.
    @Test("a stale sample zeroes the velocity rather than integrating a huge step")
    func staleSamplesAreDiscarded() {
        var tracker = CircularDragTracker()
        tracker.update(point: point(atDegrees: 0), centre: centre, timestamp: 0)
        tracker.update(point: point(atDegrees: -90), centre: centre, timestamp: 5)

        #expect(tracker.angularVelocity == 0)
        #expect(tracker.engagement == .disengaged)
    }

    @Test("lifting the finger disengages")
    func endDisengages() {
        var tracker = drag(through: [0, 10, 20, 30])
        tracker.end()

        #expect(tracker.angularVelocity == 0)
        #expect(tracker.engagement == .disengaged)
    }
}
