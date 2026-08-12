//
//  CrankRatchetTests.swift
//  CheeseHeistTests
//
//  The crank refuses to turn backwards.
//
//  Colouring a backwards turn red was the previous answer and it did not work in the
//  classroom — children turned the wrong way anyway, and a warning about a thing that
//  is happening is weaker than the thing not happening. So the knob now will not follow
//  an anticlockwise finger at all.
//
//  This has to agree with `CircularDragTracker`, which decides the same question for the
//  physics: both read clockwise-positive in screen space, where y grows downward. If the
//  two ever disagreed, the knob would stick while the cheese rose, or the reverse.
//

import Foundation
import SwiftUI
import Testing
@testable import Cheese_Heist

struct CrankRatchetTests {

    private func degrees(_ value: Double) -> Angle { .degrees(value) }

    @Test("a clockwise step is allowed")
    func clockwiseAdvances() {
        #expect(CrankRatchet.advances(from: degrees(0), to: degrees(10)))
    }

    @Test("an anticlockwise step is refused")
    func anticlockwiseIsRefused() {
        #expect(!CrankRatchet.advances(from: degrees(10), to: degrees(0)))
    }

    /// Crossing due west must not read as most of a turn backwards — the step is taken
    /// the short way round, the same as the tracker takes it.
    @Test("the wrap at 180 degrees is stepped the short way")
    func wrapTakesTheShortPath() {
        #expect(CrankRatchet.advances(from: degrees(177), to: degrees(-177)))
        #expect(!CrankRatchet.advances(from: degrees(-177), to: degrees(177)))
    }

    /// A finger resting on the ring jitters both ways by a fraction of a degree. Without
    /// a deadband the knob would creep backwards a hair at a time.
    @Test("jitter smaller than the deadband moves nothing")
    func jitterIsIgnored() {
        let hair = CrankRatchet.deadband / 4
        #expect(!CrankRatchet.advances(from: .radians(0), to: .radians(hair)))
        #expect(!CrankRatchet.advances(from: .radians(0), to: .radians(-hair)))
    }

    /// The ratchet and the physics must call the same direction forwards. This walks a
    /// clockwise drag past both and expects them to agree.
    @Test("the ratchet agrees with the tracker about which way is forwards")
    func agreesWithTheTracker() {
        let centre = CGPoint(x: 100, y: 100)
        var tracker = CircularDragTracker()
        var previous = Angle.degrees(0)
        var allAdvanced = true

        for step in 1...6 {
            let angle = Angle.degrees(Double(step) * 10)
            allAdvanced = allAdvanced && CrankRatchet.advances(from: previous, to: angle)
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

        #expect(allAdvanced)
        #expect(tracker.engagement == .engaged)
    }
}
