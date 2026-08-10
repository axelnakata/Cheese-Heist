//
//  SpotlightSubject.swift
//  Cheese Heist
//
//  What the teaching spotlight is currently cut around.
//
//  A subject, not a rectangle: the gears move on screen as the child moves, so the
//  hole has to be re-derived from a live projection every frame rather than baked into
//  a phase.
//

enum SpotlightSubject: Equatable, Sendable {
    case none
    case driverGear
    /// The follower and the rope it winds — one hole covering both, as in the
    /// `teachingFollower` frame.
    case followerGearAndRope
    case joystick
}
