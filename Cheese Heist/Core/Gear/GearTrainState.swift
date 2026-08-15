// GearTrainState.swift — Cheese Heist
// Mutable state for the gear train simulation.

struct GearTrainState: Equatable, Sendable {
    /// Driver gear angle, in radians (clockwise positive).
    var driverAngle: Double = 0
    /// Current cheese height above rest, in metres.
    var height: Double = 0
    /// Which way the ratchet is being driven this frame.
    var drive: CrankDrive = .holding

    /// The mouse's pedalling animation plays only while actually winching up — not
    /// while holding steady or unwinding, neither of which the mouse is doing.
    var isCranking: Bool { drive == .rising }

    /// Follower angle derived from driver — never integrated independently.
    /// Independent integration accumulates float drift and the teeth visibly unmesh.
    /// The SIGN FLIP is the whole of LO-2 (meshed gears turn opposite ways) and must
    /// never be shortcut.
    func followerAngle(ratio: Double) -> Double {
        -driverAngle / ratio
    }
}
