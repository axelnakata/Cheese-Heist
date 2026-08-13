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

@MainActor
@Observable
final class BlueprintViewModel {

    let steps: [BlueprintStep] = BlueprintScript.steps

    private(set) var stepIndex = 0

    var currentStep: BlueprintStep { steps[stepIndex] }
    var isFirstStep: Bool { stepIndex == 0 }
    private var isLastStep: Bool { stepIndex == steps.count - 1 }

    func goBack() {
        guard !isFirstStep else { return }
        stepIndex -= 1
    }

    /// `true` once the last step's Next is tapped — the caller hands off to Level 1.
    func goNext() -> Bool {
        guard !isLastStep else { return true }
        stepIndex += 1
        return false
    }
    func onAppear() {
            // Otomatis memutar BGM "Blueprint.wav"
            // Musik "main menu" dari Splash/Cutscene akan otomatis diganti dengan BGM ini
            AudioManager.shared.playBGM(.page2)
        }
}
