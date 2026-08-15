//
//  BlueprintCheckInBubble.swift
//  Cheese Heist
//
//  The mouse peeking in with a line of encouragement, on `BlueprintViewModel`'s timer.
//  Styled to match `BlueprintView`'s own raw fonts/colours rather than the app design
//  system — this screen was ported from the reference build and doesn't route through
//  `AppFont`/`AppColor` (see `BlueprintView.swift`'s header comment).
//

import SwiftUI

struct BlueprintCheckInBubble: View {

    let text: String

    private enum Metric {
        static let mouseHeight: CGFloat = 160
        static let cornerRadius: CGFloat = 20
        static let fontSize: CGFloat = 28
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image("Mouse_peeking")
                .resizable()
                .scaledToFit()
                .frame(height: Metric.mouseHeight)

            Text(text)
                .font(.custom("ChalkboardSE-Bold", size: Metric.fontSize))
                .foregroundColor(.black)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: Metric.cornerRadius)
                        .fill(Color.white)
                )
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.35).ignoresSafeArea()
        BlueprintCheckInBubble(text: BlueprintScript.checkInLine)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(24)
    }
}
