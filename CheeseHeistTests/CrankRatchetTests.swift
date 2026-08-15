//
//  CrankRatchetTests.swift
//  CheeseHeistTests
//
//  `CrankRatchet.delta` is the signed shortest step between two angles — the shared
//  arithmetic the knob and `CircularDragTracker` both build their idea of "which way is
//  forwards" from. If the two ever disagreed about the sign, the knob would spin one way
//  while the cheese rose the other.
//

import Foundation
import SwiftUI
import Testing
@testable import Cheese_Heist

struct CrankRatchetTests {

    private func degrees(_ value: Double) -> Angle { .degrees(value) }

    @Test("a clockwise step is a positive delta")
    func clockwiseIsPositive() {
        #expect(CrankRatchet.delta(from: degrees(0), to: degrees(10)) > 0)
    }

    @Test("an anticlockwise step is a negative delta")
    func anticlockwiseIsNegative() {
        #expect(CrankRatchet.delta(from: degrees(10), to: degrees(0)) < 0)
    }

    /// Crossing due west must not read as most of a turn the other way — the step is
    /// taken the short way round, the same as the tracker takes it.
    @Test("the wrap at 180 degrees is stepped the short way")
    func wrapTakesTheShortPath() {
        #expect(CrankRatchet.delta(from: degrees(177), to: degrees(-177)) > 0)
        #expect(CrankRatchet.delta(from: degrees(-177), to: degrees(177)) < 0)
    }

    /// A finger resting on the ring jitters both ways by a fraction of a degree. Without
    /// a deadband the knob would creep a hair at a time even standing still.
    @Test("jitter smaller than the deadband is within the deadband")
    func jitterIsWithinDeadband() {
        let hair = CrankRatchet.deadband / 4
        #expect(abs(CrankRatchet.delta(from: .radians(0), to: .radians(hair))) < CrankRatchet.deadband)
        #expect(abs(CrankRatchet.delta(from: .radians(0), to: .radians(-hair))) < CrankRatchet.deadband)
    }

    /// `delta` and the physics tracker must call the same direction forwards. This
    /// walks a clockwise drag past both and expects them to agree.
    @Test("delta agrees with the tracker about which way is forwards")
    func agreesWithTheTracker() {
        let centre = CGPoint(x: 100, y: 100)
        var tracker = CircularDragTracker()
        var previous = Angle.degrees(0)
        var allPositive = true

        for step in 1...6 {
            let angle = Angle.degrees(Double(step) * 10)
            allPositive = allPositive && CrankRatchet.delta(from: previous, to: angle) > 0
            previous = angle

            tracker.update(
                point: CGPoint(
                    x: centre.x + 80 * cos(angle.radians),
                    y: centre.y + 80 * sin(angle.radians)
                ),
                centre: centre,
                timestamp: Double(step) / 60
            )
        }

        #expect(allPositive)
        #expect(tracker.engagement == .engaged)
    }
}
