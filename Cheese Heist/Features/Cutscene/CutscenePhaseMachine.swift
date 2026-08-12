//
//  CutscenePhaseMachine.swift
//  Cheese Heist
//
//  PRD-Cutscene §7.1 — the transition table, and nothing else.
//
//  PURE AND TOTAL. `nil` means "ignore this event in this phase" — same contract as
//  `Level1PhaseMachine`. `beatCount` is passed in rather than read from `CutsceneScript`
//  so the machine stays pure and the transition table is testable without the script.
//
//  The last beat is advanced by `.tappedBlueprint`, never `.tappedContinue` — that is
//  what makes the blueprint the only tappable thing in beat 6.
//

enum CutscenePhaseMachine {

    static func next(
        from phase: CutscenePhase,
        on event: CutsceneEvent,
        beatCount: Int
    ) -> CutscenePhase? {
        switch (phase, event) {
        case (.scanning, .tappedSurface):
            return .introducing

        case (.introducing, .tappedContinue):
            return .narrating(0)

        case (.narrating(let index), .tappedContinue):
            let next = index + 1
            // The LAST beat (beatCount - 1) cannot be advanced by a tap — only the
            // blueprint exits it. All earlier beats advance normally.
            guard next < beatCount, index < beatCount - 1 else { return nil }
            return .narrating(next)

        case (.narrating(let index), .tappedBlueprint):
            // Only the last beat responds to a blueprint tap.
            guard index == beatCount - 1 else { return nil }
            return .handingOff

        default:
            return nil
        }
    }
}
