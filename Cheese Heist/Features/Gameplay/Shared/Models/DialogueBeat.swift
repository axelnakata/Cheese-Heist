//
//  DialogueBeat.swift
//  Cheese Heist
//
//  One speech bubble's worth of copy.
//
//  The emphasis is carried as data rather than as a pre-built `AttributedString` so the
//  model stays free of SwiftUI and the role colours resolve at render time — which is
//  what makes "driver gear" render in the SAME blue as the gear it is pointing at,
//  from one token, rather than from a colour baked into a string.
//
//  `role` is optional: `nil` means plain bold with no gear-role colour. This is the
//  additive change that lets the cutscene's beats 5 and 6 bold "crane" and "this
//  blueprint" without inventing a fake gear role for them.
//

import Foundation

struct DialogueBeat: Equatable, Sendable, Identifiable {
    let id: UUID
    let text: String

    /// Phrases to set in bold, optionally in a role's colour.
    let emphasis: [Emphasis]

    struct Emphasis: Equatable, Sendable {
        let phrase: String
        /// `nil` = plain bold, no colour override.
        let role: GearRole?
    }

    init(_ text: String, emphasis: [Emphasis] = []) {
        self.id = UUID()
        self.text = text
        self.emphasis = emphasis
    }

    static func driver(_ text: String, _ phrase: String) -> DialogueBeat {
        DialogueBeat(text, emphasis: [Emphasis(phrase: phrase, role: .driver)])
    }

    static func follower(_ text: String, _ phrase: String) -> DialogueBeat {
        DialogueBeat(text, emphasis: [Emphasis(phrase: phrase, role: .follower)])
    }

    /// Plain bold with no gear-role colour — for the cutscene's "crane" and "this
    /// blueprint" emphasis.
    static func bold(_ text: String, _ phrase: String) -> DialogueBeat {
        DialogueBeat(text, emphasis: [Emphasis(phrase: phrase, role: nil)])
    }
}
