// LiftSegment.swift — Cheese Heist
// PRD-Level1 §7.1 — the half/full ceiling lives here and nowhere else.
// Core/Gear has no concept of "guided" vs "free".

struct LiftSegment: Equatable, Sendable {
    /// Fraction of liftHeight this segment allows (0…1).
    let ceilingFraction: Double

    static let half = LiftSegment(ceilingFraction: 0.5)
    static let full = LiftSegment(ceilingFraction: 1.0)
}
