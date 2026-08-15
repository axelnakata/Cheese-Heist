// CrankDrive.swift — Cheese Heist
// PRD §6.5 — the ratchet has three states, not two: turning it lifts, holding it
// steady freezes, and letting go or turning it backwards unwinds.

enum CrankDrive: Equatable, Sendable {
    /// Correct-direction crank input — height climbs, gears turn forward.
    case rising
    /// A finger is on the ring but not turning it — height and gears hold still.
    case holding
    /// Wrong-way input, or no finger on the ring at all — height unwinds toward the
    /// table and the gears run backward, exactly as fast as they would have climbed.
    case falling
}
