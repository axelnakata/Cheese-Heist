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

        // Detection never times out during Level 1 setup (`DetectionTimeoutPolicy
        // .disabled`) — `.timedOut` cannot occur. `.unavailable` (the detector failed
        // to load) is a build/device problem, not a flow this phase machine models;
        // the alignment illustration is what's left on screen, same as `.idle`/
        // `.searching`.
        case .idle, .searching, .timedOut, .unavailable:
            break
        }
    }

    /// The pair and the roles the teaching run starts on, or nil if the lock has not
    /// produced two usable gears yet.
    private func lockedPair() -> (pair: GearPair, assignment: GearRoleAssignment)? {
        // `gearsLeftToRight`, not `gears`: this has to agree with the assignment
        // `AppServices` built the scene from, or the mouse would perch on one gear while
        // the physics ran the other one's tooth count.
        guard let assignment = Level1SceneDirector.initialAssignment(
                  leftToRight: detection.gearsLeftToRight
              ),
              let pair = Level1SceneDirector.pair(for: detection.gears, assignment: assignment)
        else { return nil }
        return (pair, assignment)
    }
}
