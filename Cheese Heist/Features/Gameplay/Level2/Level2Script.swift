// Level2Script.swift — Cheese Heist
// PRD-Level2 §7 — all text content for Level 2.
// Adding a result variation must not require touching the ViewModel.

enum Level2Script {

    // MARK: - HUD

    static let selectingRoles = "Tap one of the gear to set it as a driver"
    static let alignment = "Put your crane on the center of the camera"

    // MARK: - Success — 3 stars

    static let success3Title = "CHEESE SECURED!"
    static let success3Subtitle = "Great gear combination! Just the right mix!"

    // MARK: - Success — 2 stars

    static let success2Title = "Got the Cheese!"
    static let success2Subtitle = "Nice! Good gear combo!"

    // MARK: - Success — 1 star

    static let success1Title = "Phew, got it!"
    static let success1Subtitle = "Your gears pulled through!"

    // MARK: - Fail — weak

    static let failWeakTitle = "Let's use a stronger gear!"
    static let failWeakSubtitle = "Try switching which gear i should turn!"

    // MARK: - Fail — slow

    static let failSlowTitle = "So close! Let's be quicker!"
    static let failSlowSubtitle = "Try switching which gear i should turn!"

    /// Picks the title/subtitle pair for a given star count (0 = fail).
    static func resultCopy(
        stars: Int, isFail: Bool, isWeak: Bool
    ) -> (title: String, subtitle: String) {
        if isFail {
            return isWeak
                ? (failWeakTitle, failWeakSubtitle)
                : (failSlowTitle, failSlowSubtitle)
        }
        switch stars {
        case 3: return (success3Title, success3Subtitle)
        case 2: return (success2Title, success2Subtitle)
        default: return (success1Title, success1Subtitle)
        }
    }
}
