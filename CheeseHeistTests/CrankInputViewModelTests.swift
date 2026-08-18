//
//  CrankInputViewModelTests.swift
//  CheeseHeistTests
//
//  `drive` is the three-way ratchet: cranking correctly rises, resting a finger on the
//  ring holds, and cranking backwards OR lifting the finger off entirely falls. The
//  first two are just `engagement` renamed; the last one is the new distinction this
//  view model has to make that `CircularDragTracker` alone cannot, because the tracker
//  reports the same `.disengaged` for both "resting" and "gone".
//

import CoreGraphics
import Foundation
import Testing
@testable import Cheese_Heist

@MainActor
struct CrankInputViewModelTests {

    let centre = CGPoint(x: 100, y: 100)
    let radius: CGFloat = 80

    private func point(atDegrees degrees: Double) -> CGPoint {
        let radians = degrees * .pi / 180
        return CGPoint(
            x: centre.x + radius * cos(radians),
            y: centre.y + radius * sin(radians)
        )
    }

    @Test("turning clockwise rises")
    func clockwiseRises() {
        let crank = CrankInputViewModel()
        for (index, degrees) in [0.0, 10, 20, 30].enumerated() {
            crank.drag(to: point(atDegrees: degrees), centre: centre, timestamp: Double(index) / 60)
        }
        #expect(crank.drive == .rising)
    }

    @Test("turning anticlockwise falls")
    func anticlockwiseFalls() {
        let crank = CrankInputViewModel()
        for (index, degrees) in [0.0, -10, -20, -30].enumerated() {
            crank.drag(to: point(atDegrees: degrees), centre: centre, timestamp: Double(index) / 60)
        }
        #expect(crank.drive == .falling)
    }

    /// A finger resting on the ring — still down, not turning it — holds rather than
    /// falls. This is the case `engagement` alone cannot tell apart from letting go.
    @Test("a finger resting on the ring holds")
    func restingFingerHolds() {
        let crank = CrankInputViewModel()
        crank.drag(to: point(atDegrees: 0), centre: centre, timestamp: 0)
        crank.drag(to: point(atDegrees: 0.05), centre: centre, timestamp: 1.0 / 60)

        #expect(crank.drive == .holding)
    }

    /// Lifting the finger off entirely is different from resting it: the crank falls.
    @Test("releasing falls")
    func releasingFalls() {
        let crank = CrankInputViewModel()
        for (index, degrees) in [0.0, 10, 20, 30].enumerated() {
            crank.drag(to: point(atDegrees: degrees), centre: centre, timestamp: Double(index) / 60)
        }
        #expect(crank.drive == .rising)

        crank.release()
        #expect(crank.drive == .falling)
    }

    /// A finger left in place with no new samples arriving eventually settles — and
    /// because it never lifted, that settling reads as holding, not falling.
    @Test("a stationary finger settles to holding, not falling")
    func stationaryFingerSettlesToHolding() {
        let crank = CrankInputViewModel()
        for (index, degrees) in [0.0, 10, 20, 30].enumerated() {
            crank.drag(to: point(atDegrees: degrees), centre: centre, timestamp: Double(index) / 60)
        }
        #expect(crank.drive == .rising)

        crank.refresh(now: 3.0 / 60 + CircularDragTracker.staleAfter + 0.1)
        #expect(crank.drive == .holding)
    }

    @Test("an untouched crank falls")
    func untouchedCrankFalls() {
        let crank = CrankInputViewModel()
        #expect(crank.drive == .falling)
    }

    @Test("crank hint transitions from falling to idle when elevation hits bottom")
    func hintTransitionsWhenElevationHitsBottom() {
        let crank = CrankInputViewModel()
        // Untouched while elevated -> falling hint (auto-unwinds)
        let elevatedHint = CrankHint.of(
            drive: crank.drive, isPressed: crank.isPressed, hasElevation: true
        )
        #expect(elevatedHint == .falling)

        // Untouched at bottom -> idle hint (auto-unwind stopped)
        let bottomHint = CrankHint.of(
            drive: crank.drive, isPressed: crank.isPressed, hasElevation: false
        )
        #expect(bottomHint == .idle)

        // Pressed & turning backwards mid-lift -> wrongWay (red alert)
        let midLiftWrongWay = CrankHint.of(
            drive: .falling, isPressed: true, hasElevation: true
        )
        #expect(midLiftWrongWay == .wrongWay)

        // Pressed & turning backwards at the bottom -> idle (stays clockwise focused)
        let bottomWrongWay = CrankHint.of(
            drive: .falling, isPressed: true, hasElevation: false
        )
        #expect(bottomWrongWay == .idle)
    }
}
