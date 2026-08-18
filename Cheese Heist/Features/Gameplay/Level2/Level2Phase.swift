// Level2Phase.swift — Cheese Heist
// PRD-Level2 §9 — the Level 2 flow.
//
// Unlike Level 1, there are no tutorial phases — the child already learned
// driver/follower in L1. Level 2 goes straight from detection to role selection.
// The two fail states (`failedWeak` and `failedSlow`) are what make this level
// the puzzle: the child must discover which assignment lifts the cheese in time.

enum Level2Phase: String, CaseIterable, Equatable, Sendable {
    case aligningCrane
    case detectingGears
    case selectingRoles
    case rolesChosen
    case cranking
    case stallShaking      // gear shakes for `Level2Tuning.stallShakeDuration` before failedWeak
    case succeeded
    case failedWeak
    case failedSlow

    /// How far this phase is allowed to lift. Only `cranking` lifts, and always to full.
    var liftSegment: LiftSegment? {
        switch self {
        case .cranking: return .full
        default: return nil
        }
    }
}
