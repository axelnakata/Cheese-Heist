//
//  CutscenePhaseCommands.swift
//  Cheese Heist
//
//  Phase-entry side effects, extracted from the ViewModel to keep `handle` five lines.
//  Same separation as `Level1PhaseCommands`: the ViewModel transitions, commands execute.
//

enum CutscenePhaseCommands {

    struct Context {
        let scene: (any CutsceneSceneProviding)?
        let dialogue: DialogueSequencer
        let setBeat: (CutsceneBeat?) -> Void
        let setBlueprint: (Bool) -> Void
        let onHandoff: (() -> Void)?
    }

    static func apply(_ phase: CutscenePhase, in ctx: Context) {
        switch phase {
        case .scanning:
            break

        case .introducing:
            ctx.scene?.placeScene()
            ctx.scene?.setRingVisible(false)
            ctx.setBeat(nil)
            ctx.setBlueprint(false)

        case .narrating(let index):
            let beat = CutsceneScript.beats[index]
            ctx.setBeat(beat)
            ctx.setBlueprint(beat.showsBlueprint)
            ctx.dialogue.present([beat.dialogue])

        case .handingOff:
            ctx.setBeat(nil)
            ctx.setBlueprint(false)
            ctx.dialogue.reset()
            ctx.scene?.teardown()
            ctx.onHandoff?()
        }
    }
}
