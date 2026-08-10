//
//  CircularDragTracker.swift
//  Cheese Heist
//
//  Turns a finger dragging round a ring into "is the child cranking, and which way?".
//
//  Pure and frame-independent: it takes points and a timestamp and returns an angular
//  velocity, so it is fully unit-testable without a gesture, a view or a device.
//
//  WHY IT TRACKS DIRECTION AT ALL, GIVEN THAT THE JOYSTICK IS ONLY AN ENGAGEMENT GATE:
//  Turning it the wrong way has to do NOTHING rather than lower the cheese. A child who
//  cranks backwards and sees the cheese descend has learned that the crank controls
//  height directly, which is the opposite of the ratchet the crane actually has.
//

import CoreGraphics
import Foundation

struct CircularDragTracker {

    /// Below this the finger is resting on the ring rather than turning it, in radians
    /// per second. Roughly a tenth of a turn a second.
    static let engagementThreshold: Double = 0.6

    /// How long a gap in samples before the drag counts as stopped, in seconds.
    /// One dropped frame must not read as the child letting go.
    static let staleAfter: TimeInterval = 0.15

    private var lastAngle: Double?
    private var lastTimestamp: TimeInterval?

    private(set) var angularVelocity: Double = 0

    /// One drag sample. `centre` is the ring's centre in the same space as `point`.
    mutating func update(point: CGPoint, centre: CGPoint, timestamp: TimeInterval) {
        // Screen y grows DOWNWARD, which makes this a left-handed frame — so a raw
        // atan2 already increases clockwise, which is the direction that cranks. No
        // flip: negating here would silently make the wrong-way hint fire on the
        // correct direction.
        let angle = atan2(Double(point.y - centre.y), Double(point.x - centre.x))

        defer {
            lastAngle = angle
            lastTimestamp = timestamp
        }

        guard let lastAngle, let lastTimestamp else { return }

        let elapsed = timestamp - lastTimestamp
        guard elapsed > 0, elapsed < Self.staleAfter else {
            angularVelocity = 0
            return
        }

        angularVelocity = Double(
            AngleHelper.shortestDelta(from: Float(lastAngle), to: Float(angle))
        ) / elapsed
    }

    /// The finger left the ring.
    mutating func end() {
        lastAngle = nil
        lastTimestamp = nil
        angularVelocity = 0
    }

    /// What the current motion amounts to.
    ///
    /// Clockwise is positive in screen space, and clockwise is the direction that
    /// cranks: it matches the way the mouse is drawn turning the driver.
    var engagement: CrankEngagement {
        if angularVelocity < -Self.engagementThreshold { return .wrongWay }
        if angularVelocity > Self.engagementThreshold { return .engaged }
        return .disengaged
    }
}
