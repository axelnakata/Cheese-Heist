//
//  BlueprintModel.swift
//  Cheese Heist
//
//  PRD §11.4 — one step of the 3-step build guide. Ported from the reference build
//  (`cheezy-dev-nay`'s `TutorialStep`): instructions are markdown directly, so
//  `Text(LocalizedStringKey)` renders `**bold**` spans for free instead of going
//  through a hand-rolled `AttributedString` pass.
//

import SwiftUI

struct BlueprintStep: Identifiable {
    let id: Int
    let title: String
    let stepLabel: String
    let gifName: String
    let instructions: [LocalizedStringKey]
    let checkInLine: String
}
