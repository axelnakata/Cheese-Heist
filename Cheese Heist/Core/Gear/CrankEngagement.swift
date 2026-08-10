// CrankEngagement.swift — Cheese Heist
// PRD §6.5 — joystick is an engagement gate, not a throttle.

enum CrankEngagement: Equatable, Sendable {
    /// Clockwise input detected — mouse cranks at ω_driver.
    case engaged
    /// No input or input stopped.
    case disengaged
    /// Counter-clockwise input — produces no rotation, triggers a hint.
    case wrongWay
}
