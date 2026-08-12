//
//  BlueprintInstructionList.swift
//  Cheese Heist
//
//  Numbered instructions with markdown bold spans — ported from the reference build,
//  which renders `**phrase**` through `Text(LocalizedStringKey)` directly rather than a
//  hand-rolled `AttributedString` pass.
//

import SwiftUI

struct BlueprintInstructionList: View {

    let instructions: [LocalizedStringKey]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                row(number: index + 1, instruction: instruction)
            }
        }
    }

    private func row(number: Int, instruction: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if instructions.count > 1 {
                Text("\(number).")
                    .font(.system(size: 25, weight: .regular))
            }
            Text(instruction)
                .font(.system(size: 25, weight: .regular))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(.white)
    }
}

#Preview {
    BlueprintInstructionList(instructions: BlueprintScript.steps[1].instructions)
        .previewBackdrop(.cameraFeed)
}
