//
//  CutscenePhase.swift
//  Cheese Heist
//
//  PRD-Cutscene §7.1 — the cutscene flow, from surface detection through the six
//  narrative beats to the Level 1 handoff.
//
//  `.scanning` replaces the parent PRD's `.surfaceScan` route — override C-2 keeps it
//  as an internal phase rather than a separate route, because routing between them would
//  rebuild the view tree that owns the AR anchor.
//

enum CutscenePhase: Equatable, Sendable {
    /// Surface guidance; ring shown when valid, ✗ when not.
    case scanning
    /// Cheese + cat placed; no dialogue; tap to continue.
    case introducing
    /// Beats 0…4 — the mouse narrates.
    case narrating(Int)
    /// Terminal — the view routes to `.level1`.
    case handingOff
}
