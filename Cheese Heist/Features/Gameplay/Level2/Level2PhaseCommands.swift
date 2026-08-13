// Level2PhaseCommands.swift — Cheese Heist
// PRD-Level2 §9.1 — side effects of entering each phase.
//
// Like Level 1's `PhaseCommands`, this is what keeps `Level2ViewModel.handle(_:)` to
// five lines. The entry effects go here; the ViewModel just runs the machine.

import Foundation

/// Everything a Level 2 phase's entry effects are allowed to touch.
@MainActor
struct Level2PhaseContext {
    let director: Level2SceneDirector?
    let runner: LiftRunner?
    let selection: GearSelectionViewModel
    let crank: CrankInputViewModel
    let detection: GearDetectionService
    let onTeardown: () -> Void
}

@MainActor
enum Level2PhaseCommands {

    /// Everything that happens on the way INTO `phase`.
    static func apply(_ phase: Level2Phase, in context: Level2PhaseContext) {
        context.director?.stage(phase)

        // The crank is released on every non-crank transition.
        if !Level2InputGate.of(phase).joystickEnabled { context.crank.release() }

        applyLift(phase, in: context)
        applyLifecycle(phase, in: context)
    }

    private static func applyLift(_ phase: Level2Phase, in context: Level2PhaseContext) {
        // The cheese drops back to the table when roles are re-selected.
        if phase == .selectingRoles || phase == .rolesChosen {
            context.runner?.reset()
            return
        }

        guard let segment = phase.liftSegment else {
            context.runner?.segment = nil
            return
        }
        context.runner?.continueInto(segment)
    }

    private static func applyLifecycle(_ phase: Level2Phase, in context: Level2PhaseContext) {
        guard phase == .aligningCrane else { return }

        context.selection.reset()
        context.detection.reset()
        context.onTeardown()
    }
}
