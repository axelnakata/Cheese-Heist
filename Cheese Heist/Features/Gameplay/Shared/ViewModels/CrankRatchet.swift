//
//  CrankRatchet.swift
//  Cheese Heist
//
//  "How far did the finger really turn, from here to there?"
//
//  ═══ IT USED TO BLOCK BACKWARDS ENTIRELY. ═══
//
//  Turning the joystick backwards used to do nothing to the crane, so refusing to let
//  the KNOB follow a backward finger read as "the crank refuses" rather than a broken
//  control. That is no longer true — a wrong-way turn (or letting go) now lets the rope
//  fall — so the knob has to be able to follow the finger both ways. `delta` answers the
//  direction-and-magnitude question; `CircularJoystickView` decides what to do with it.
//
//  Pure, and separate from the view, because "which way is forwards" is the same
//  question `CircularDragTracker` answers for the physics and the two must not be able
//  to disagree — both read clockwise-positive in screen space, where y grows downward.
//

import Foundation
import SwiftUI

enum CrankRatchet {

    /// Below this, in radians, the finger is resting on the ring rather than turning
    /// it. A finger resting on the ring jitters by a fraction of a degree either way,
    /// and treating that as real rotation would make the knob creep on its own.
    static let deadband: Double = 0.004

    /// The signed shortest step from `current` to `touch`, clockwise positive.
    ///
    /// Taken the SHORT way round, so crossing due west reads as a few degrees rather
    /// than most of a turn the other way.
    static func delta(from current: Angle, to touch: Angle) -> Double {
        Double(AngleHelper.shortestDelta(
            from: Float(current.radians), to: Float(touch.radians)
        ))
    }
}
