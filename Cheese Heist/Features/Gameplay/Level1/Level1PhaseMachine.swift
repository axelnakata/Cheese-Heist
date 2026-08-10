//
//  Level1PhaseMachine.swift
//  Cheese Heist
//
//  The PRD-Level1 §8 transition table, and nothing else.
//
//  PURE AND TOTAL. `nil` means "ignore this event in this phase" — it is a legitimate
//  answer, not a failure, and it is what lets the view fire `tappedContinue` on every
//  tap without asking whether taps mean anything right now.
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
            ?? teaching(from: phase, on: event)
            ?? handover(from: phase, on: event)
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
            return .introDialogue

        case (.aligningCrane, .detectionTimedOut),
             (.detectingGears, .detectionTimedOut):
            return .manualFallback

        // The detector keeps tracking behind the sheet, so a late lock is still taken.
        case (.manualFallback, .manualPairChosen),
             (.manualFallback, .detectionLocked):
            return .introDialogue

        default:
            return nil
        }
    }

    /// Phases 4–9: the guided run. `introDialogue` is two beats, but the sequencer owns
    /// the index — this only sees the tap that leaves the last one.
    private static func teaching(from phase: Level1Phase, on event: Level1Event) -> Level1Phase? {
        switch (phase, event) {
        case (.introDialogue, .tappedContinue):     return .teachingDriver
        case (.teachingDriver, .tappedContinue):    return .teachingJoystick
        case (.teachingJoystick, .tappedContinue):  return .guidedCrankToHalf
        case (.guidedCrankToHalf, .liftReachedCeiling):  return .teachingFollower
        case (.teachingFollower, .tappedContinue):  return .guidedCrankToFull
        case (.guidedCrankToFull, .liftReachedCeiling):  return .handOver
        default: return nil
        }
    }

    /// Phases 10–13: the child's own run.
    private static func handover(from phase: Level1Phase, on event: Level1Event) -> Level1Phase? {
        switch (phase, event) {
        case (.handOver, .tappedContinue):
            return .selectingRoles

        // Re-entering the same phase is deliberate: the reassignment is an entry
        // effect, so a tap that swaps the roles runs it exactly like any other
        // transition rather than through a side door.
        case (.selectingRoles, .tappedGear):
            return .selectingRoles

        case (.selectingRoles, .tappedPull):
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
