//
//  Level1PhaseCommands.swift
//  Cheese Heist
//
//  The side effects of ENTERING a phase, in one place.
//
//  This is what keeps `Level1ViewModel.handle(_:)` to five lines. Without it every
//  entry effect becomes a case in the ViewModel's switch, the ViewModel grows past its
//  160-line cap, and — worse — the effects drift apart from the §8 table they are
//  supposed to implement.
//

import Foundation

/// Everything a phase's entry effects are allowed to touch.
///
/// Bundled rather than passed one by one so that adding a collaborator does not change
/// the shape of every call site, and so the set of things an entry effect can reach is
/// visible in one place.
@MainActor
struct Level1PhaseContext {
    let director: Level1SceneDirector?
    let runner: LiftRunner?
    let selection: GearSelectionViewModel
    let dialogue: DialogueSequencer
    let crank: CrankInputViewModel
    let detection: GearDetectionService
    /// The live star count, read into the success celebration's particle burst.
    let starCount: Int
    let onTeardown: () -> Void
}

@MainActor
enum Level1PhaseCommands {

    /// Everything that happens on the way INTO `phase`.
    static func apply(_ phase: Level1Phase, in context: Level1PhaseContext) {
        context.dialogue.present(Level1PhasePresentation.beats(for: phase))
        context.director?.stage(phase)

        // The crank is released on every transition. A phase that does not accept
        // cranking must not inherit a finger that was already down when it started.
        if !Level1InputGate.of(phase).joystickEnabled { context.crank.release() }

        applyLift(phase, in: context)
        applyLifecycle(phase, in: context)
        applyAudioAndEffects(phase, in: context)
    }

    /// BGM ducks out of the way the instant the free run starts and comes back with the
    /// success celebration's particle burst. See `AudioManager.fadeOutBGM`/`fadeInBGM`.
    private static func applyAudioAndEffects(_ phase: Level1Phase, in context: Level1PhaseContext) {
        switch phase {
        case .freeCrank:
            AudioManager.shared.fadeOutBGM()
        case .succeeded:
            context.director?.celebrate(starCount: context.starCount)
            AudioManager.shared.fadeInBGM()
        default:
            break
        }
    }

    /// Where the cheese is allowed to go, and when it drops back.
    private static func applyLift(_ phase: Level1Phase, in context: Level1PhaseContext) {
        // The cheese returns to the table while the child is still CHOOSING, not when
        // the free run starts — whether they have picked a driver yet or are still
        // free to change it.
        guard phase != .selectingRoles, phase != .rolesChosen else {
            context.runner?.reset()
            return
        }

        guard let segment = phase.liftSegment else {
            context.runner?.segment = nil
            return
        }
        context.runner?.continueInto(segment)
    }

    private static func applyLifecycle(_ phase: Level1Phase, in context: Level1PhaseContext) {
        // Retry. The scene goes; the ARSession NEVER does — a second `session.run`
        // silently invalidates every world anchor (risk R-L5).
        guard phase == .aligningCrane else { return }

        context.selection.reset()
        context.detection.reset()

        // Last, and after the reset: the host releases the scene AND starts the
        // detector looking again. Resetting after that would stop the search it just
        // began, and the child would sit on the alignment illustration forever.
        context.onTeardown()
    }
}
