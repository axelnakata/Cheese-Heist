// GearTrainState.swift — Cheese Heist
// Mutable state for the gear train simulation.

struct GearTrainState: Equatable, Sendable {
    /// Driver gear angle, in radians (clockwise positive).
    var driverAngle: Double = 0
    /// Current cheese height above rest, in metres.
    var height: Double = 0
    /// Whether the mouse is actively cranking.
    var isCranking: Bool = false

    /// Follower angle derived from driver — never integrated independently.
    /// Independent integration accumulates float drift and the teeth visibly unmesh.
    func followerAngle(ratio: Double) -> Double {
        -driverAngle / ratio
    }
}
