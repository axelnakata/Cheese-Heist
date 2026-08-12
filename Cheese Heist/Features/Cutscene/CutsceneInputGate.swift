//
//  CutsceneInputGate.swift
//  Cheese Heist
//
//  Phase → what is interactive. Pure.
//
//  `CutsceneView` passes this down and no view asks "what phase are we in" — the same
//  contract as `Level1InputGate`.
//

struct CutsceneInputGate: Equatable, Sendable {
    let surfaceTappable: Bool
    let tapAdvances: Bool
    let blueprintTappable: Bool

    static func of(_ phase: CutscenePhase, isSurfaceValid: Bool = false) -> CutsceneInputGate {
        switch phase {
        case .scanning:
            return CutsceneInputGate(
                surfaceTappable: isSurfaceValid,
                tapAdvances: false,
                blueprintTappable: false
            )

        case .introducing:
            return CutsceneInputGate(
                surfaceTappable: false,
                tapAdvances: true,
                blueprintTappable: false
            )

        case .narrating(let index):
            let isLastBeat = index == CutsceneScript.beats.count - 1
            return CutsceneInputGate(
                surfaceTappable: false,
                tapAdvances: !isLastBeat,
                blueprintTappable: isLastBeat
            )

        case .handingOff:
            return .none
        }
    }

    static let none = CutsceneInputGate(
        surfaceTappable: false,
        tapAdvances: false,
        blueprintTappable: false
    )
}
