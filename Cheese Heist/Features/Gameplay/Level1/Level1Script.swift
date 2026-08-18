//
//  Level1Script.swift
//  Cheese Heist
//
//  Every word Level 1 says, verbatim from the Figma frames.
//
//  Content, not logic. `Level1PhasePresentation` decides which of these a phase shows.
//

enum Level1Script {

    /// Shown in the navy chip before a driver is picked — an instruction, not the
    /// mouse talking.
    static let selectingRoles = "Tap one of the gear to set it as a driver"

    /// The mouse's one line, said once the driver is picked — while the joystick is
    /// already live and the child can still change their mind.
    static let teachDriverFollower: [DialogueBeat] = [
        DialogueBeat(
            "Driver Gear is the gear I turn that controls the Follower Gear.",
            emphasis: [
                .init(phrase: "Driver Gear", role: .driver),
                .init(phrase: "Follower Gear", role: .follower)
            ]
        )
    ]

    static let alignment = "Put your crane on the center of the camera"

    static let wrongGearCountTitle = "I need exactly 2 gears to build this crane! Let's fix that and try again."
    static let wrongGearCountButton = "I fixed it!"

    static let craneLostSpeech = "Where did your crane go? Put your crane back on the center of the camera!"

    static let successTitle = "CHEESE SECURED!"
    static let successSubtitle = "Great job!"
}
