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

    /// Twelve seconds without a lock.
    case detectionTimedOut

    /// The child picked the pair themselves from the fallback sheet.
    case manualPairChosen(pair: GearPair, assignment: GearRoleAssignment)

    /// A tap anywhere the current phase treats as "next".
    case tappedContinue

    /// The lift reached this phase's ceiling.
    case liftReachedCeiling

    /// A gear was tapped during role selection.
    case tappedGear(id: UUID)

    /// PULL. Locks the assignment and swaps in the joystick.
    case tappedPull

    case tappedRetry
    case tappedNext

    /// ARKit tracking notes. HUD only — these NEVER change the phase.
    case trackingLost
    case trackingRegained
}
