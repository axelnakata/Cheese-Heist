//
//  CrankHint.swift
//  Cheese Heist
//
//  Which of the joystick's three teaching animations to show, if any.
//
//  `CrankEngagement` answers "what is the finger doing right now"; this answers "what
//  does the CHILD need to be told right now", which is a different question once the
//  ring is showing while nobody is touching it at all. Kept out of `CrankInputViewModel`
//  itself because it also needs to know whether there is still height to lose — a fact
//  that lives on `LiftRunner`, not on the crank.
//

enum CrankHint: Equatable, Sendable {
    /// Cranking correctly, or holding the ring steady — nothing to say.
    case none
    /// Not touching the ring, and nothing is unwinding: the default "turn this way".
    case idle
    /// Actively turning the ring backwards.
    case wrongWay
    /// Let go (or turned it backwards) while the cheese still has height to lose.
    case falling

    static func of(drive: CrankDrive, isPressed: Bool, hasElevation: Bool) -> CrankHint {
        guard isPressed else { return hasElevation ? .falling : .idle }
        if drive == .falling {
            return hasElevation ? .wrongWay : .idle
        }
        return .none
    }
}
