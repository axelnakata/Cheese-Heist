//
//  ResultEffectKind.swift
//  Cheese Heist
//
//  What flavour of one-shot particle burst plays over the crane when a level ends.
//  A plain value type — same reason `CraneSceneProviding` carries no RealityKit type —
//  so both ViewModels can ask for it without importing RealityKit.
//

enum ResultEffectKind: Equatable, Sendable {
    /// Cheese secured — a small shower of cheese-gold sparks. `starCount` scales how
    /// much plays (1–3): a bare 1-star clear still reads as a win, never a full show.
    case success(starCount: Int)

    /// A stall or a timeout — a soft grey puff, the opposite gesture from `success`.
    /// One look for both fail reasons; the overlay's title carries which one it was.
    case fail
}
