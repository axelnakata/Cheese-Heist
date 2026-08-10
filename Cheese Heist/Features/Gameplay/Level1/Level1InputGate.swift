//
//  Level1InputGate.swift
//  Cheese Heist
//
//  Phase -> what is interactive. Pure.
//
//  `Level1View` passes this down and no view asks "what phase are we in" — which would
//  put the phase switch in three places and let them disagree about, say, whether the
//  gears are tappable during a dialogue beat.
//

struct Level1InputGate: Equatable, Sendable {
    let gearsTappable: Bool
    let joystickEnabled: Bool
    let pullVisible: Bool
    let tapAdvances: Bool

    static func of(_ phase: Level1Phase) -> Level1InputGate {
        switch phase {
        // Nothing to touch: the illustration comes down when the DETECTOR is ready, not
        // when the child taps. Tapping past it would leave them detecting from a
        // viewpoint the model cannot work with.
        case .aligningCrane, .detectingGears, .manualFallback:
            return .none

        case .introDialogue, .teachingDriver, .teachingJoystick,
             .teachingFollower, .handOver:
            return .init(gearsTappable: false, joystickEnabled: false,
                         pullVisible: false, tapAdvances: true)

        case .guidedCrankToHalf, .guidedCrankToFull, .freeCrank:
            return .init(gearsTappable: false, joystickEnabled: true,
                         pullVisible: false, tapAdvances: false)

        // PULL visible means the roles stay changeable — D-2.
        case .selectingRoles:
            return .init(gearsTappable: true, joystickEnabled: false,
                         pullVisible: true, tapAdvances: false)

        // The success overlay owns its own buttons.
        case .succeeded:
            return .none
        }
    }

    static let none = Level1InputGate(
        gearsTappable: false, joystickEnabled: false, pullVisible: false, tapAdvances: false
    )
}
