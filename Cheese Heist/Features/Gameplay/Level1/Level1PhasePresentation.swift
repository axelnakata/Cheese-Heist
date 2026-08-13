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
        // `aligningCrane` deliberately has NO chip: `CraneAlignmentLayer` draws that
        // title itself, as bare white text. Returning it here too would render the same
        // sentence twice, once in a navy chip and once under it.
        case .detectingGears: return Level1Script.detecting
        case .handOver, .selectingRoles: return Level1Script.handOver
        case .teachingJoystick, .guidedCrankToHalf, .guidedCrankToFull, .freeCrank:
            return Level1Script.crankPrompt
        default:
            return nil
        }
    }

    /// The mouse's lines for this phase, or empty when it has nothing to say.
    static func beats(for phase: Level1Phase) -> [DialogueBeat] {
        switch phase {
        case .introDialogue:    return Level1Script.intro
        case .teachingDriver:   return Level1Script.teachDriver
        case .teachingFollower: return Level1Script.teachFollower
        default:                return []
        }
    }

    /// Whether the alignment illustration and its scrim are on screen.
    static func showsAlignmentIllustration(_ phase: Level1Phase) -> Bool {
        phase == .aligningCrane || phase == .detectingGears
    }
}
