//
//  BlueprintCheckInBubble.swift
//  Cheese Heist
//
//  The mouse peeking in with a line of encouragement, on `BlueprintViewModel`'s timer.
//  Styled to match `BlueprintView`'s own raw fonts/colours rather than the app design
//  system — this screen was ported from the reference build and doesn't route through
//  `AppFont`/`AppColor` (see `BlueprintView.swift`'s header comment).
//

//import SwiftUI
//
//struct BlueprintCheckInBubble: View {
//
//    let text: String
//
//    private enum Metric {
//        static let mouseHeight: CGFloat = 160
//        static let cornerRadius: CGFloat = 20
//        static let fontSize: CGFloat = 28
//    }
//
//    var body: some View {
//        HStack(alignment: .top, spacing: 12) {
//            Image("Mouse_peeking")
//                .resizable()
//                .scaledToFit()
//                .frame(height: Metric.mouseHeight)
//
//            Text(text)
//                .font(.custom("ChalkboardSE-Bold", size: Metric.fontSize))
//                .foregroundColor(.black)
//                .padding(16)
//                .background(
//                    RoundedRectangle(cornerRadius: Metric.cornerRadius)
//                        .fill(Color.white)
//                )
//        }
//        .allowsHitTesting(false)
//    }
//}
//
//#Preview {
//    ZStack {
//        Color.black.opacity(0.35).ignoresSafeArea()
//        BlueprintCheckInBubble(text: BlueprintScript.checkInLine)
//            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
//            .padding(24)
//    }
//}

import SwiftUI

struct BlueprintCheckInBubble: View {
    
    let text: String
    
    private enum Metric {
        static let mouseHeight: CGFloat = 400
        static let cornerRadius: CGFloat = 28
        static let shadowDepth: CGFloat = 10
        static let tailSize = CGSize(width: 20, height: 24)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: -18) {
            Image("Mouse_peeking")
                .resizable()
                .scaledToFit()
                .frame(height: Metric.mouseHeight)
                .zIndex(1)
            
            Text(text)
                .font(.custom("ChalkboardSE-Bold", size: 22))
                .foregroundColor(AppColor.textPrimary)
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
                .padding(.leading, Metric.tailSize.width)
                .background(
                    ZStack {
                        GeometryReader { geo in
                            let bodyWidth = max(0, geo.size.width - Metric.tailSize.width)
                            RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous)
                                .fill(Palette.darkParchment)
                                .frame(width: bodyWidth, height: geo.size.height)
                                .offset(x: Metric.tailSize.width, y: Metric.shadowDepth)
                        }
                        
                        // Bubble utama
                        SpeechBubbleShape(
                            cornerRadius: Metric.cornerRadius,
                            tailSize: Metric.tailSize
                        )
                        .fill(Palette.parchment)
                    }
                )
                .offset(x: -50, y: -150)
        }
        .padding(.bottom, 50)
        .padding(.leading, -5)
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.35).ignoresSafeArea()
        BlueprintCheckInBubble(text: "Are you still there? Let's finish this crane!")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}
