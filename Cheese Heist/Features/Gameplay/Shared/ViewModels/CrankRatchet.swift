//
//  CrankRatchet.swift
//  Cheese Heist
//
//  "May the knob move from here to there?" — clockwise only.
//
//  A real crane's winch has a ratchet, and the app has always half-modelled it: turning
//  the joystick backwards produced no lift. What it did not do was stop the KNOB, so the
//  control travelled backwards under the finger while the crane ignored it, and the only
//  sign anything was wrong was a colour change. Children turned the wrong way anyway.
//
//  Pure, and separate from the view, because "which way is forwards" is the same
//  question `CircularDragTracker` answers for the physics and the two must not be able
//  to disagree — both read clockwise-positive in screen space, where y grows downward.
//

import Foundation
import SwiftUI

enum CrankRatchet {

    /// Ignore steps smaller than this, in radians. A finger resting on the ring jitters
    /// by a fraction of a degree either way, and letting the knob creep backwards a
    /// hair at a time would defeat the whole thing.
    static let deadband: Double = 0.004

    /// Whether the knob is allowed to follow the finger from `current` to `touch`.
    ///
    /// The step is taken the SHORT way round, so crossing due west reads as a few
    /// degrees rather than most of a turn backwards.
    static func advances(from current: Angle, to touch: Angle) -> Bool {
        delta(from: current, to: touch) > deadband
    }

    /// The signed shortest step, clockwise positive.
    static func delta(from current: Angle, to touch: Angle) -> Double {
        Double(AngleHelper.shortestDelta(
            from: Float(current.radians), to: Float(touch.radians)
        ))
    }
}
