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

    static func of(_ phase: Level1Phase) -> Level1InputGate {
        switch phase {
        // Nothing to touch: the illustration comes down when the DETECTOR is ready, not
        // when the child taps. Tapping past it would leave them detecting from a
        // viewpoint the model cannot work with.
        case .aligningCrane, .detectingGears, .manualFallback:
            return .none

        // Gears are pickable straight away — no PULL button. Tapping stays live in
        // `rolesChosen` too, so the choice is still theirs right up to the moment they
        // actually turn the joystick — see `Level1PhaseMachine`.
        case .selectingRoles:
            return .init(gearsTappable: true, joystickEnabled: false)

        case .rolesChosen:
            return .init(gearsTappable: true, joystickEnabled: true)

        case .freeCrank:
            return .init(gearsTappable: false, joystickEnabled: true)

        // The success overlay owns its own buttons.
        case .succeeded:
            return .none
        }
    }

    static let none = Level1InputGate(gearsTappable: false, joystickEnabled: false)
}
