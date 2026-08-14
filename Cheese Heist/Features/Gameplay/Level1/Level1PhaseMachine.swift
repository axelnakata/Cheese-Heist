//
//  Level1PhaseMachine.swift
//  Cheese Heist
//
//  The Level 1 transition table, and nothing else.
//
//  PURE AND TOTAL. `nil` means "ignore this event in this phase" — it is a legitimate
//  answer, not a failure.
//
//  This is the highest-value test surface in the feature: the entire flow is verifiable
//  as a table test before a single pixel exists.
//

enum Level1PhaseMachine {

    static func next(from phase: Level1Phase, on event: Level1Event) -> Level1Phase? {
        // Tracking is a HUD note, never a phase change. Losing the gears behind a hand
        // must not knock the child out of a lesson — the anchor is still holding the
        // scene exactly where it was.
        if event == .trackingLost || event == .trackingRegained { return nil }

        return detection(from: phase, on: event)
            ?? play(from: phase, on: event)
    }

    /// Phases 1–3: get a pair of gears, one way or the other.
    private static func detection(from phase: Level1Phase, on event: Level1Event) -> Level1Phase? {
        switch (phase, event) {
        case (.aligningCrane, .detectionViable):
            return .detectingGears

        // A lock is accepted straight off the illustration as well as out of
        // `detectingGears`. The detector reaches both states from the same tick and
        // nothing guarantees the viability signal is delivered first — and if the lock
        // arrives alone, refusing it here is what leaves the child holding a framed,
        // recognised crane behind an illustration that never comes down.
        case (.aligningCrane, .detectionLocked),
             (.detectingGears, .detectionLocked):
            return .selectingRoles

        case (.aligningCrane, .detectionTimedOut),
             (.detectingGears, .detectionTimedOut):
            return .manualFallback

        // The detector keeps tracking behind the sheet, so a late lock is still taken —
        // there is no manual choice, only "try looking again".
        case (.manualFallback, .detectionLocked):
            return .selectingRoles

        default:
            return nil
        }
    }

    /// Phases 4–7: pick a driver, get shown once what it means while the joystick is
    /// already live, then the child's own run.
    private static func play(from phase: Level1Phase, on event: Level1Event) -> Level1Phase? {
        switch (phase, event) {
        case (.selectingRoles, .tappedGear):
            return .rolesChosen

        // Re-entering the same phase is deliberate: the reassignment is an entry
        // effect, so a tap that swaps the roles runs it exactly like any other
        // transition rather than through a side door.
        case (.rolesChosen, .tappedGear):
            return .rolesChosen

        // The first turn of the joystick locks the choice and starts the free run.
        case (.rolesChosen, .joystickEngaged):
            return .freeCrank

        case (.freeCrank, .liftReachedCeiling):
            return .succeeded

        // Retry returns to the ILLUSTRATION, not to role selection: the child may well
        // have put the iPad down, and the crane has to be found again. The ARSession is
        // never restarted — see `Level1PhaseCommands`.
        case (.succeeded, .tappedRetry):
            return .aligningCrane

        // `Next` is a no-op in this release (OQ-L2).
        case (.succeeded, .tappedNext):
            return nil

        default:
            return nil
        }
    }
}
