// LiftOutcome.swift — Cheese Heist
// PRD §6.4 — whether the lift succeeded or stalled.

enum LiftOutcome: Equatable, Sendable {
    /// Cheese reached the ceiling.
    case reachedCeiling
    /// The gears stalled — i · η · τ_stall ≤ τ_load.
    /// Level 1 is tuned so this branch is unreachable.
    case stalled
}
