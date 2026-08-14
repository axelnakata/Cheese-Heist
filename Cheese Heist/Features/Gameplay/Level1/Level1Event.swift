//
//  Level1Event.swift
//  Cheese Heist
//
//  Everything that can happen to Level 1.
//
//  Deliberately carries no ARKit, RealityKit or simd type — see PRD-Level1 §6.3. A
//  locked pair arrives as two `GearType`s and a `GearRoleAssignment` of `UUID`s, which
//  is all the ViewModel is entitled to know about the scene.
//

import Foundation

enum Level1Event: Equatable, Sendable {

    /// The detector can see gears — the alignment illustration has done its job.
    /// Replaces the parent PRD §11.5.1 plane/distance/stillness gate.
    case detectionViable

    /// A pair was locked, with the roles the teaching run starts on.
    case detectionLocked(pair: GearPair, assignment: GearRoleAssignment)

    /// Twelve seconds without a lock. There is no manual fallback — "Try looking
    /// again" restarts the detector and waits for a real lock, same as the first try.
    case detectionTimedOut

    /// The lift reached this phase's ceiling.
    case liftReachedCeiling

    /// A gear was tapped during role selection.
    case tappedGear(id: UUID)

    /// The child turned the joystick for the first time. Locks the assignment and
    /// starts the free run — mirrors `Level2Event.joystickEngaged`.
    case joystickEngaged

    case tappedRetry
    case tappedNext

    /// ARKit tracking notes. HUD only — these NEVER change the phase.
    case trackingLost
    case trackingRegained
}
