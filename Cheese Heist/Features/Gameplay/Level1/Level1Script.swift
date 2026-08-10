//
//  Level1Script.swift
//  Cheese Heist
//
//  Every word Level 1 says, verbatim from the Figma frames — including the typo in the
//  hand-over line, which is what the design says and is not this file's to fix.
//
//  Content, not logic. `Level1PhasePresentation` decides which of these a phase shows.
//

enum Level1Script {

    /// Beat 1 and beat 2 of `introDialogue`. Two bubbles, one tap apart.
    static let intro: [DialogueBeat] = [
        DialogueBeat("Wow! Great job on making this crane!"),
        DialogueBeat(
            "Now, choosing the driver and follower gear is very important.",
            emphasis: [
                .init(phrase: "driver", role: .driver),
                .init(phrase: "follower", role: .follower)
            ]
        )
    ]

    static let teachDriver: [DialogueBeat] = [
        .driver(
            "Look at the gear under my feet! This is the driver gear, "
                + "it's the gear I turn to start pulling!",
            "driver gear"
        )
    ]

    static let teachFollower: [DialogueBeat] = [
        .follower(
            "Now look at the gear holding the rope! This is the follower gear, "
                + "it turns with the driver gear to pull up the cheese!",
            "follower gear"
        )
    ]

    /// Shown in the navy chip rather than a bubble — it is an instruction, not the
    /// mouse talking.
    static let handOver = "It's your turn! Tap on of the gear to set it as a driver"

    static let alignment = "Put your crane on the center of the camera"
    static let detecting = "Looking at your gears…"
    static let crankPrompt = "Turn the joystick to crank!"

    static let successTitle = "CHEESE SECURED!"
    static let successSubtitle = "Great job!"
}
