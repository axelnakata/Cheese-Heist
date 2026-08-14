// Level2PhasePresentation.swift — Cheese Heist
// PRD-Level2 §6 — what the HUD should show in each phase.
// Pure functions over `Level2Phase`, no state.

enum Level2PhasePresentation {

    /// Instruction chip text, or nil if no chip is shown.
    static func chip(for phase: Level2Phase) -> String? {
        switch phase {
        case .selectingRoles: return Level2Script.selectingRoles
        default: return nil
        }
    }

    /// Whether the alignment illustration should be shown.
    ///
    /// Includes `manualFallback`: there is no manual picker, only "try looking again",
    /// which restarts the detector without changing the phase — the illustration has
    /// to already be behind the sheet so it is what's left once the sheet dismisses.
    static func showsAlignmentIllustration(_ phase: Level2Phase) -> Bool {
        phase == .aligningCrane || phase == .detectingGears || phase == .manualFallback
    }

    /// Whether the strength/speed bars should be visible.
    static func showsBars(_ phase: Level2Phase) -> Bool {
        switch phase {
        case .cranking, .stallShaking: return true
        default: return false
        }
    }

    /// Whether the cheese countdown icons should be visible in the HUD.
    static func showsCheeseCountdown(_ phase: Level2Phase) -> Bool {
        false
    }

    /// Whether the timer badge should be visible.
    static func showsTimer(_ phase: Level2Phase) -> Bool {
        switch phase {
        case .selectingRoles, .rolesChosen, .cranking, .stallShaking:
            return true
        default:
            return false
        }
    }

    /// Whether the role labels should be visible. Shown during gear setup only, hidden when cranking.
    static func showsRoleLabels(_ phase: Level2Phase) -> Bool {
        phase == .rolesChosen
    }

    /// Whether a result overlay (success or fail) should be shown.
    static func isResult(_ phase: Level2Phase) -> Bool {
        switch phase {
        case .succeeded, .failedWeak, .failedSlow: return true
        default: return false
        }
    }
}
