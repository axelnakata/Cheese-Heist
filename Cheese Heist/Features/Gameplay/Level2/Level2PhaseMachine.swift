// Level2PhaseMachine.swift — Cheese Heist
// PRD-Level2 §9.1 — pure, stateless transition table.
// Returns nil for "ignore this event in this phase".
//
// The whole machine is this file. `Level2ViewModel.handle` calls it, checks nil,
// and applies. The transition table is the highest-value test surface — the
// entire flow is verified as a table test before a single pixel exists.

enum Level2PhaseMachine {

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    static func next(from phase: Level2Phase, on event: Level2Event) -> Level2Phase? {
        switch (phase, event) {

        // — Detection
        case (.aligningCrane, .detectionViable):
            return .detectingGears

        case (.detectingGears, .detectionLocked):
            return .selectingRoles

        case (.detectingGears, .detectionTimedOut):
            return .manualFallback

        case (.manualFallback, .manualPairChosen):
            return .selectingRoles

        // — Role selection
        case (.selectingRoles, .tappedGear):
            return .rolesChosen

        case (.rolesChosen, .tappedGear):
            return .rolesChosen

        // — Joystick engagement locks the choice and starts the timer
        case (.rolesChosen, .joystickEngaged):
            return .cranking

        // — Cranking outcomes
        case (.cranking, .liftReachedCeiling):
            return .succeeded

        case (.cranking, .timerExpired):
            return .failedSlow

        case (.cranking, .stallDetected):
            return .stallShaking

        case (.stallShaking, .shakeCompleted):
            return .failedWeak

        // — Result actions
        case (.succeeded, .tappedRetry):
            return .aligningCrane

        case (.succeeded, .tappedNext):
            // no-op — Level 3 does not exist yet
            return nil

        case (.failedWeak, .tappedRetry):
            return .aligningCrane

        case (.failedSlow, .tappedRetry):
            return .aligningCrane

        // — Restart from anywhere except result screens and alignment
        case (.selectingRoles, .tappedRestart),
             (.rolesChosen, .tappedRestart),
             (.cranking, .tappedRestart),
             (.stallShaking, .tappedRestart):
            return .aligningCrane

        default:
            return nil
        }
    }
}
