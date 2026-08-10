//
//  DialogueBeatText.swift
//  Cheese Heist
//
//  Renders a `DialogueBeat` into an `AttributedString`, resolving each emphasis to its
//  role token. The one place the two halves of the dialogue meet.
//

import SwiftUI

enum DialogueBeatText {

    static func attributed(_ beat: DialogueBeat) -> AttributedString {
        var string = AttributedString(beat.text)

        for emphasis in beat.emphasis {
            guard let range = string.range(of: emphasis.phrase) else { continue }
            string[range].foregroundColor = colour(for: emphasis.role)
            string[range].inlinePresentationIntent = .stronglyEmphasized
        }

        return string
    }

    private static func colour(for role: GearRole) -> Color {
        role == .driver ? AppColor.roleDriver : AppColor.roleFollower
    }
}
