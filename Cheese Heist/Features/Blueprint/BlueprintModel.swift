//
//  BlueprintModel.swift
//  Cheese Heist
//
//  PRD §11.4 — one step of the 3-step build guide.
//
//  Instructions carry bold phrases as data, not as a pre-built `AttributedString` —
//  the same split `DialogueBeat` uses, so the model stays free of SwiftUI and the
//  render-time conversion lives once, in `BlueprintInstructionList`.
//

struct BlueprintStep: Identifiable {
    let id: Int
    let title: String
    let stepLabel: String
    let media: BlueprintMedia
    let instructions: [Instruction]

    struct Instruction: Equatable {
        let text: String
        let boldPhrases: [String]

        init(_ text: String, bold boldPhrases: [String] = []) {
            self.text = text
            self.boldPhrases = boldPhrases
        }
    }
}

/// `BlueprintMediaView`'s content. v1 ships `.gif` (Nay's build-along clips); `.image`
/// covers a static fallback; `.video` is stubbed so a future MP4 clip is a data change,
/// not a code change (PRD §11.4 OQ-9).
enum BlueprintMedia {
    case image(String)
    case gif(String)
    case video(String)
}
