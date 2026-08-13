//
//  Level2ViewModel+DetectionObserver.swift
//  Cheese Heist
//
//  Translates the detector's own lifecycle into `Level2Event`s.
//  Same pattern as Level 1 — reads `@Observable` properties at ~2 Hz.

import Foundation

extension Level2ViewModel {

    /// One observation of the detector's published state.
    func observeDetection() {
        switch detection.phase {
        case .searching where detection.isViable:
            handle(.detectionViable)

        case .locked:
            guard let locked = lockedPair() else { return }
            handle(.detectionLocked(locked.pair, locked.assignment))

        case .timedOut, .unavailable:
            handle(.detectionTimedOut)

        case .idle, .searching:
            break
        }
    }

    /// The pair and the roles, built from the detection lock.
    private func lockedPair() -> (pair: GearPair, assignment: GearRoleAssignment)? {
        guard let assignment = Level2SceneDirector.initialAssignment(
                  leftToRight: detection.gearsLeftToRight
              ),
              let pair = Level2SceneDirector.pair(for: detection.gears, assignment: assignment)
        else { return nil }
        return (pair, assignment)
    }

    /// The child chose the gears themselves after a timeout.
    func chooseManualPair(_ first: GearType, _ second: GearType) {
        guard let assignment = Level2SceneDirector.initialAssignment(
            leftToRight: detection.gearsLeftToRight
        ) ?? placeholderAssignment() else { return }

        let ordered = first.teeth <= second.teeth ? (first, second) : (second, first)
        handle(.manualPairChosen(
            GearPair(driver: ordered.0, follower: ordered.1),
            assignment
        ))
    }

    private func placeholderAssignment() -> GearRoleAssignment? {
        GearRoleAssignment(driverID: UUID(), followerID: UUID())
    }
}
