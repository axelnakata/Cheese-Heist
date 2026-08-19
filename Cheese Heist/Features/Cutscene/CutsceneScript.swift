//
//  CutsceneScript.swift
//  Cheese Heist
//
//  Every word the cutscene says, verbatim from the Figma frames (Docs/cutscene frames/).
//
//  Content, not logic. Adding a beat must not require touching the ViewModel (§11.3).
//

enum CutsceneScript {

    /// The 5 narrative beats — PRD-Cutscene §6.2, matching cutscene 2…6.png.
    static let beats: [CutsceneBeat] = [
        // Beat 0 (cutscene 2): mouse appears, happy.
        CutsceneBeat(
            dialogue: DialogueBeat(
                "Hi there! I'm super hungry… let's find something yummy to eat!"
            ),
            pose: .happy,
            showsBlueprint: false
        ),
        // Beat 1 (cutscene 3): sees the cheese, shocked happy.
        CutsceneBeat(
            dialogue: DialogueBeat(
                "Oh, look! Is that a cheese right there?!"
            ),
            pose: .amazed,
            showsBlueprint: false
        ),
        // Beat 2 (cutscene 4): notices the cat, struggle.
        CutsceneBeat(
            dialogue: DialogueBeat(
                "But, wait! That cat over there doesn't look friendly…"
            ),
            pose: .talkStruggle,
            showsBlueprint: false
        ),
        // Beat 3 (cutscene 5): idea, "crane" bolded.
        CutsceneBeat(
            dialogue: DialogueBeat.bold(
                "What if we build something to help us? Like a crane!",
                "crane"
            ),
            pose: .think,
            showsBlueprint: false
        ),
        // Beat 4 (cutscene 6): blueprint call to action, "this blueprint" bolded.
        CutsceneBeat(
            dialogue: DialogueBeat.bold(
                "Open this blueprint to help me build one!",
                "this blueprint"
            ),
            pose: .happy,
            showsBlueprint: true
        )
    ]

    // MARK: - Surface scan copy

    /// Shown when the surface IS valid — two-line chip.
    static let scanValid = ["Find a flat surface.", "Tap on the green circle to start!"]

    /// Shown when the surface is NOT valid — single-line fallback (OQ-C4).
    static let scanInvalid = "Look for a flat surface!"

    /// Header label on `RecommendedPositionStrip`.
    static let recommendedPositionTitle = "Recommended Position"
}
