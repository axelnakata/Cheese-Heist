//
//  CrankInputViewModel.swift
//  Cheese Heist
//
//  Joystick drag -> `isCranking`.
//
//  The joystick is an ENGAGEMENT GATE, not a throttle. How fast the child turns it
//  changes nothing about how fast the cheese rises — that number comes out of the gear
//  ratio, which is the entire lesson. If cranking harder lifted faster, the child would
//  learn that effort beats gearing.
//

import CoreGraphics
import Foundation
import Observation

@MainActor
@Observable
final class CrankInputViewModel {

    private(set) var engagement: CrankEngagement = .disengaged

    /// True while the child is turning the joystick the right way.
    var isCranking: Bool { engagement == .engaged }

    /// True while they are turning it backwards — the hint reads off this.
    var isWrongWay: Bool { engagement == .wrongWay }

    @ObservationIgnored private var tracker = CircularDragTracker()

    /// Called on every drag change.
    func drag(to point: CGPoint, centre: CGPoint, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        tracker.update(point: point, centre: centre, timestamp: timestamp)
        engagement = tracker.engagement
    }

    /// Called when the drag ends, and whenever input is gated off.
    func release() {
        tracker.end()
        engagement = .disengaged
    }
}
