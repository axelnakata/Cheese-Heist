//
//  BlueprintViewModel.swift
//  Cheese Heist
//
//  Owns only the current step index. `LargeCTAButton(.next)` on the last step means
//  "hand off to Level 1", not "advance" — `goNext()` tells the caller which one just
//  happened instead of holding a completion closure itself, so the type stays pure and
//  testable, the same shape as `CutscenePhaseMachine`'s "nil means ignore".
//

import Observation
import SwiftUI

@MainActor
@Observable
final class BlueprintViewModel {

    let steps: [BlueprintStep] = BlueprintScript.steps

    private(set) var stepIndex = 0

    /// Whether the mouse's mid-build check-in is currently showing.
    private(set) var showsCheckIn = false

    private var checkInTask: Task<Void, Never>?

    private enum CheckInTiming {
        static let interval: Duration = .seconds(10)
        static let visibleDuration: Duration = .seconds(5)
    }

    var currentStep: BlueprintStep { steps[stepIndex] }
    var isFirstStep: Bool { stepIndex == 0 }
    private var isLastStep: Bool { stepIndex == steps.count - 1 }

    func goBack() {
        guard !isFirstStep else { return }
                stepIndex -= 1
                userDidInteract()
    }

    /// `true` once the last step's Next is tapped — the caller hands off to Level 1.
    func goNext() -> Bool {
        guard !isLastStep else {
                    userDidInteract()
                    return true
                }
                stepIndex += 1
                userDidInteract() // Reset timer saat user menekan next
                return false
    }

    func onAppear() {
        // Otomatis memutar BGM "Blueprint.wav"
        // Musik "main menu" dari Splash/Cutscene akan otomatis diganti dengan BGM ini
        AudioManager.shared.playBGM(.page2)
        startCheckInLoop()
    }

    func onDisappear() {
        checkInTask?.cancel()
    }

    /// Resets the idle timer loop on any user interaction.
    func userDidInteract() {
        showsCheckIn = false
        startCheckInLoop()
    }

    /// Peeks the mouse in on a fixed cadence, for as long as the screen is up.
    private func startCheckInLoop() {
        checkInTask?.cancel()
        checkInTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: CheckInTiming.interval)
                guard !Task.isCancelled, let self else { return }

                self.showsCheckIn = true
                try? await Task.sleep(for: CheckInTiming.visibleDuration)
                guard !Task.isCancelled else { return }

                showsCheckIn = false
            }
        }
    }
}
