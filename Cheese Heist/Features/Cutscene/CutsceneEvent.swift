//
//  CutsceneEvent.swift
//  Cheese Heist
//
//  PRD-Cutscene §7.1 — the inputs the cutscene's phase machine accepts.
//

enum CutsceneEvent: Equatable, Sendable {
    /// The child tapped while the surface ring is valid.
    case tappedSurface
    /// A tap anywhere that is not the blueprint — advances dialogue or the introducing beat.
    case tappedContinue
    /// The blueprint scroll was tapped in beat 6.
    case tappedBlueprint
}
