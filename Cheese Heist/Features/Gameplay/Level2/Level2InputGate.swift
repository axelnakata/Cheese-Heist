// Level2InputGate.swift — Cheese Heist
// PRD-Level2 §9 — what is interactive in each phase.
// No view asks "what phase are we in" — it reads these flags.

struct Level2InputGate: Equatable {
    let gearsTappable: Bool
    let joystickEnabled: Bool
    let restartVisible: Bool
    let timerActive: Bool

    static func of(_ phase: Level2Phase) -> Level2InputGate {
        switch phase {
        case .selectingRoles:
            return Level2InputGate(
                gearsTappable: true, joystickEnabled: false,
                restartVisible: false, timerActive: false
            )
        case .rolesChosen:
            return Level2InputGate(
                gearsTappable: true, joystickEnabled: true,
                restartVisible: true, timerActive: false
            )
        case .cranking:
            return Level2InputGate(
                gearsTappable: false, joystickEnabled: true,
                restartVisible: true, timerActive: true
            )
        case .stallShaking:
            return Level2InputGate(
                gearsTappable: false, joystickEnabled: false,
                restartVisible: true, timerActive: true
            )
        default:
            return Level2InputGate(
                gearsTappable: false, joystickEnabled: false,
                restartVisible: false, timerActive: false
            )
        }
    }
}
