// AppDuration.swift — Cheese Heist
// PRD §7 — standard animation durations so timing is consistent.

import Foundation

enum AppDuration {
    /// Standard state transition (phase changes, chip swap).
    static let transition: Double = 0.3
    /// Short ease-out (button press, label appear).
    static let easeOut: Double = 0.25
    /// Typewriter reveal speed, characters per second.
    static let typewriterCPS: Double = 40
    /// Success screen entry.
    static let celebrationEntry: Double = 0.6
}
