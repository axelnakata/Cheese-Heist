//
//  SplashViewModel.swift
//  Cheese Heist
//
//  Ported from the reference build (`cheezy-dev-nay`) — `isGearRotating` drives both
//  gears' `.animation(value:)` bindings directly in `SplashView`, which is the exact
//  mechanism verified there. `tapToPlay()` adds a single-fire guard so the tap gesture
//  cannot invoke the app's navigation closure twice.
//

import Observation

@MainActor
@Observable
final class SplashViewModel {

    let model = SplashModel.level1

    private(set) var isGearRotating = false
    private(set) var hasTapped = false

    func startAnimations() {
        isGearRotating = true
    }

    /// `true` the first time it's called; further taps while handing off are ignored.
    func tapToPlay() -> Bool {
        guard !hasTapped else { return false }
        hasTapped = true
        return true
    }
}
