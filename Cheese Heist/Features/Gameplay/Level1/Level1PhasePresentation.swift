//
//  Level1PhasePresentation.swift
//  Cheese Heist
//
//  Phase -> copy. Pure, and the only place a phase is turned into words.
//

enum Level1PhasePresentation {

    /// The navy instruction chip, or nil when this phase does not use one.
    ///
    /// The chip and the speech bubble are different voices: the chip tells the CHILD
    /// what to do, the bubble is the MOUSE talking. No phase uses both.
    static func chip(for phase: Level1Phase) -> String? {
        switch phase {
        case .selectingRoles: return Level1Script.selectingRoles
        default: return nil
        }
    }

    /// The mouse's one line, said once as the joystick arms — empty everywhere else.
    static func beats(for phase: Level1Phase) -> [DialogueBeat] {
        switch phase {
        case .rolesChosen: return Level1Script.teachDriverFollower
        default:           return []
        }
    }

    /// Whether the alignment illustration and its scrim are on screen. `Level1View`
    /// hides it in favour of `WrongGearCountLayer` while a live gear-count issue is up —
    /// the two never show at once.
    static func showsAlignmentIllustration(_ phase: Level1Phase) -> Bool {
        phase == .aligningCrane || phase == .detectingGears
    }

    /// Driver/follower labels and the rope, shown once a driver has been picked and
    /// hidden again the moment the free run starts — mirrors `Level2PhasePresentation`.
    static func showsRoleLabels(_ phase: Level1Phase) -> Bool {
        phase == .rolesChosen
    }

    /// The circular drag-direction hint over the joystick — live only while the choice
    /// is still open, same window as the role labels.
    static func showsJoystickHint(_ phase: Level1Phase) -> Bool {
        phase == .rolesChosen
    }
}
