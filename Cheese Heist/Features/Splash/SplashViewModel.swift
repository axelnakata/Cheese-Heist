//
//  SplashViewModel.swift
//  Cheese Heist
//
//  Owns only the tap gate — the breathing logo and the pulsing tagline are continuous
//  loops with no state of their own (PRD §11.1), driven locally by the views that draw
//  them, the same way `BlueprintScrollView`'s glow rotation is.
//

import Observation

@MainActor
@Observable
final class SplashViewModel {

    let model = SplashModel.level1

    private(set) var hasTapped = false

    /// `true` the first time it's called; further taps during the cross-fade out are
    /// ignored so a double-tap cannot fire the handoff twice.
    func tapToPlay() -> Bool {
        guard !hasTapped else { return false }
        hasTapped = true
        return true
    }
}
