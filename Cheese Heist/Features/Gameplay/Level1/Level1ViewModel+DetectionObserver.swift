//
//  Level1ViewModel+DetectionObserver.swift
//  Cheese Heist
//
//  Translates the detector's own lifecycle into `Level1Event`s.
//
//  The SLOW path of PRD-Level1 §6.2: this reads `@Observable` properties that refresh
//  at about 2 Hz. The 6 Hz fast path never comes through here — it goes straight from
//  `GearTrackingPublisher` to `CraneAlignmentFilter`, bypassing Observation entirely,
//  because the filter needs every measurement it can get and SwiftUI needs as few as
//  possible.
//
//  DETECTION NEVER REACHES PHYSICS. The tooth counts are read once, here, at lock. An
//  improving pose estimate must never alter a run already in progress.
//

import Foundation

extension Level1ViewModel {

    /// One observation of the detector's published state. Idempotent: it fires each
    /// event at most once per lock, so it is safe to call on every republish.
    func observeDetection() {
        switch detection.phase {
        case .searching where detection.isViable:
            handle(.detectionViable)

        case .locked:
            guard let locked = lockedPair() else { return }
            handle(.detectionLocked(pair: locked.pair, assignment: locked.assignment))

        case .timedOut, .unavailable:
            handle(.detectionTimedOut)

        case .idle, .searching:
            break
        }
    }

    /// The pair and the roles the teaching run starts on, or nil if the lock has not
    /// produced two usable gears yet.
    private func lockedPair() -> (pair: GearPair, assignment: GearRoleAssignment)? {
        guard let assignment = Level1SceneDirector.initialAssignment(for: detection.gears),
              let pair = Level1SceneDirector.pair(for: detection.gears, assignment: assignment)
        else { return nil }
        return (pair, assignment)
    }

    /// The child chose the gears themselves after a timeout. The same entry effects
    /// run as for an automatic lock — there is no second scene-building path.
    func chooseManualPair(_ first: GearType, _ second: GearType) {
        guard let assignment = Level1SceneDirector.initialAssignment(for: detection.gears)
                ?? placeholderAssignment() else { return }

        let ordered = first.teeth <= second.teeth ? (first, second) : (second, first)
        handle(.manualPairChosen(
            pair: GearPair(driver: ordered.0, follower: ordered.1),
            assignment: assignment
        ))
    }

    /// A manual choice can arrive with no detected gears at all, in which case there is
    /// nothing on screen to assign roles to and the ids are freshly minted.
    private func placeholderAssignment() -> GearRoleAssignment? {
        GearRoleAssignment(driverID: UUID(), followerID: UUID())
    }
}
