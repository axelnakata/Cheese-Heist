// Level2Event.swift — Cheese Heist
// PRD-Level2 §9.1 — events that drive the Level 2 phase machine.

import Foundation

enum Level2Event: Equatable {
    // Detection
    case detectionViable
    case detectionLocked(GearPair, GearRoleAssignment)

    // Interaction
    case tappedGear(id: UUID)
    case joystickEngaged
    case tappedRestart

    // Gameplay
    case liftReachedCeiling
    case timerExpired
    case stallDetected
    case shakeCompleted

    // Result
    case tappedRetry
    case tappedNext
}
