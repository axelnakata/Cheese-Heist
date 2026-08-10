//
//  PreviewDialogue.swift
//  Cheese Heist
//
//  Dummy dialogue for component previews (PRD §8.6). The real lines live in
//  CutsceneScript / Level1Script, which are WS-2 and WS-4.
//

import SwiftUI

enum PreviewDialogue {

    static let craneCompliment = AttributedString("Wow! Great job on making this crane!")

    static let hungryMouse = AttributedString(
        "Hi there! I'm super hungry… let's find something yummy to eat!"
    )

    /// Exercises the bold-span requirement — beat 5 bolds "crane!".
    static var buildACrane: AttributedString {
        var line = AttributedString("What if we build something to help us? Like a ")
        var emphasis = AttributedString("crane!")
        emphasis.font = .custom(AppFont.dialogue.fontName, fixedSize: AppFont.dialogue.size).bold()
        line.append(emphasis)
        return line
    }
}
