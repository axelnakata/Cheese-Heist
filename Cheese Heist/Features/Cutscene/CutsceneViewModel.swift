//
//  CutsceneViewModel.swift
//  Cheese Heist
//
//  ═══ THIS TYPE NEVER IMPORTS ARKit, RealityKit, Vision OR simd. ═══
//
//  Owns the cutscene's phase, input gate, and dialogue sequencer. Communicates with
//  the AR scene exclusively through `CutsceneSceneProviding`.
//
//  Same five-line `handle` as `Level1ViewModel`: guard → transition → gate → log →
//  commands. An event the machine rejects has no effects.
//
//  ═══ THE GATE IS REFRESHED BY THE SCENE, NOT ONLY BY THE PHASE. ═══
//
//  `surfaceTappable` depends on something that changes continuously while nothing else
//  does: whether the camera is currently pointing at enough table. The first version
//  computed the gate on attach and on every phase change, which are exactly the moments
//  the surface has NOT just changed — so the gate said "not tappable" forever and the
//  ring, once it finally went green, did nothing when tapped. Validity now arrives as a
//  plain value pushed from the coordinator, which also keeps this type free of ARKit.
//

import Foundation
import Observation
import os

@MainActor
@Observable
final class CutsceneViewModel {

    private(set) var phase: CutscenePhase = .scanning
    private(set) var inputGate = CutsceneInputGate.none

    /// Pushed from the scene coordinator. The view reads this, not the scene.
    private(set) var surfaceValidity: SurfaceValidity = .noSurface

    let dialogue = DialogueSequencer()

    /// The current beat's data, when narrating.
    private(set) var currentBeat: CutsceneBeat?

    /// Whether the blueprint layer should be visible.
    private(set) var showsBlueprint = false

    @ObservationIgnored private var scene: (any CutsceneSceneProviding)?
    @ObservationIgnored var onHandoff: (() -> Void)?

    // MARK: - Scene attachment

    func attach(scene: any CutsceneSceneProviding) {
        self.scene = scene
        surfaceValidity = scene.validity
        scene.setRingVisible(true)
        updateGate()
    }

    /// Called whenever the coordinator publishes a new verdict.
    func refreshSurfaceValidity(_ validity: SurfaceValidity) {
        guard validity != surfaceValidity else { return }
        surfaceValidity = validity
        updateGate()
    }

    // MARK: - The machine

    func handle(_ event: CutsceneEvent) {
        guard let next = CutscenePhaseMachine.next(
            from: phase,
            on: event,
            beatCount: CutsceneScript.beats.count
        ) else { return }

        phase = next
        updateGate()
        Logger.cutscene.info("phase → \(String(describing: next), privacy: .public)")
        CutscenePhaseCommands.apply(next, in: context)

        // After handoff the scene is gone.
        if next == .handingOff { scene = nil }
    }

    private var context: CutscenePhaseCommands.Context {
        CutscenePhaseCommands.Context(
            scene: scene,
            dialogue: dialogue,
            setBeat: { [weak self] in self?.currentBeat = $0 },
            setBlueprint: { [weak self] in self?.showsBlueprint = $0 },
            onHandoff: onHandoff
        )
    }

    private func updateGate() {
        inputGate = CutsceneInputGate.of(phase, isSurfaceValid: surfaceValidity == .valid)
    }

    // MARK: - Input

    func tapSurface() {
        guard inputGate.surfaceTappable else { return }
        handle(.tappedSurface)
    }

    /// A tap during the typewriter completes the line; a tap after it advances the phase.
    /// The phase machine owns progression, so the sequencer is never advanced here — each
    /// phase presents its own single beat.
    func tapToContinue() {
        guard inputGate.tapAdvances else { return }
        if dialogue.current != nil, !dialogue.isRevealComplete {
            dialogue.markRevealComplete()
            return
        }
        handle(.tappedContinue)
    }

    func tapBlueprint() {
        guard inputGate.blueprintTappable else { return }
        handle(.tappedBlueprint)
    }

    // MARK: - Presentation

    var hasDialogue: Bool { dialogue.current != nil }
}
