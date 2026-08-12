//
//  CutsceneBeat.swift
//  Cheese Heist
//
//  PRD-Cutscene §7.2 — one beat of the cutscene narrative.
//
//  Content, not logic. `CutscenePhaseCommands` decides which of these a phase shows.
//

struct CutsceneBeat: Equatable, Sendable {
    let dialogue: DialogueBeat
    let pose: MouseSprite
    let showsBlueprint: Bool
}
