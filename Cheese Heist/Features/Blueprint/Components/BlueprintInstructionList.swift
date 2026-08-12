//
//  BlueprintInstructionList.swift
//  Cheese Heist
//
//  Numbered instructions with bold spans, resolved to `AttributedString` here — the one
//  place a `BlueprintStep.Instruction`'s bold phrases meet SwiftUI, mirroring
//  `DialogueBeatText`.
//

import SwiftUI

struct BlueprintInstructionList: View {

    let instructions: [BlueprintStep.Instruction]

    @Environment(\.layoutScale) private var scale

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m * scale) {
            ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                row(number: index + 1, instruction: instruction)
            }
        }
        .foregroundStyle(AppColor.textInverted)
    }

    @ViewBuilder
    private func row(number: Int, instruction: BlueprintStep.Instruction) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.xs * scale) {
            if instructions.count > 1 {
                Text("\(number).").appText(AppFont.body)
            }
            Text(Self.attributed(instruction)).appText(AppFont.body)
        }
    }

    private static func attributed(_ instruction: BlueprintStep.Instruction) -> AttributedString {
        var string = AttributedString(instruction.text)
        for phrase in instruction.boldPhrases {
            guard let range = string.range(of: phrase) else { continue }
            string[range].inlinePresentationIntent = .stronglyEmphasized
        }
        return string
    }
}

#Preview {
    BlueprintInstructionList(instructions: BlueprintScript.steps[1].instructions)
        .previewBackdrop(.cameraFeed)
}
