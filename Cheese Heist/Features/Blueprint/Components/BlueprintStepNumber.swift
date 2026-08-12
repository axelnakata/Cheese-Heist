//
//  BlueprintStepNumber.swift
//  Cheese Heist
//
//  PRD §11.4 — the large step numeral ("1/3", "2/3", "3/3"), top-right of the sheet.
//

import SwiftUI

struct BlueprintStepNumber: View {

    let text: String

    var body: some View {
        Text(text)
            .appText(AppFont.title)
            .foregroundStyle(AppColor.textInverted)
    }
}

#Preview {
    BlueprintStepNumber(text: "1/3")
        .previewBackdrop(.cameraFeed)
}
