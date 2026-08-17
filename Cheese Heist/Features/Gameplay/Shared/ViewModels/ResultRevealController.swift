//
//  ResultRevealController.swift
//  Cheese Heist
//
//  Holds the result overlay back until its win/lose SFX has finished playing. The
//  owning ViewModel's `phase` flips to the result state immediately — so input freezes
//  right away — but the overlay itself (title, star count, mouse) is a separate signal
//  that only goes true once the audio completes, so the child hears the outcome before
//  they see it. Shared by Level 1 and Level 2 rather than duplicated in both ViewModels.
//

import Foundation
import Observation

@MainActor
@Observable
final class ResultRevealController {

    private(set) var showsResult = false

    @ObservationIgnored private var task: Task<Void, Never>?

    /// Plays `track`, then reveals the result overlay once it finishes.
    func reveal(after track: AudioTrack) {
        task?.cancel()
        showsResult = false
        task = Task { [weak self] in
            await AudioManager.shared.playSFXAndWait(track: track)
            guard !Task.isCancelled else { return }
            self?.showsResult = true
        }
    }

    /// Cancels any pending reveal and hides the overlay immediately — there is no
    /// outcome to announce outside a result phase (e.g. on retry).
    func hide() {
        task?.cancel()
        showsResult = false
    }
}
