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

        // Detection never times out during setup (`DetectionTimeoutPolicy.disabled`) —
        // `.timedOut` cannot occur. `.unavailable` (the detector failed to load) is a
        // build/device problem, not a flow this phase machine models; the alignment
        // illustration is what's left on screen, same as `.idle`/`.searching`.
        case .idle, .searching, .timedOut, .unavailable:
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
}
