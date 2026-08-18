//
//  WrongGearCountLayer.swift
//  Cheese Heist
//
//  Setup-only fallback screen shown when the child builds with fewer or more than 2 gears.
//  Dismissed via "I fixed it!" button.
//

import SwiftUI

struct WrongGearCountLayer: View {
    
    let issue: GearCountIssue
    let onFixed: () -> Void
    
    @Environment(\.layoutScale) private var scale
    
    private enum Metric {
        static let titleGap: CGFloat = 40
        static let buttonGap: CGFloat = 40
        static let sideMargin: CGFloat = 100
        static let buttonPaddingHorizontal: CGFloat = 32
        static let buttonPaddingVertical: CGFloat = 12
    }
    
    var body: some View {
        ZStack {
            ScrimOverlay()
            
            VStack(spacing:1) {
                Spacer(minLength: 50)
                
                Text(Level1Script.wrongGearCountTitle)
                    .appText(AppFont.largeTitle)
                    .foregroundStyle(AppColor.textOnCamera)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                WrongGearCountIllustration()
                
                // MARK: - Button "I fixed it!"
                Button(action: onFixed) {
                    Text("I fixed it!")
                        .appText(AppFont.title)
                        .foregroundColor(.white)
                        .padding(.horizontal, Metric.buttonPaddingHorizontal * scale)
                        .padding(.vertical, Metric.buttonPaddingVertical * scale)
                        .background(
                            Capsule()
                                .fill(AppColor.accent)
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white, lineWidth: 2 * scale)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 6 * scale, x: 0, y: 3 * scale)
                }
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal, Metric.sideMargin * scale)
        }
        .ignoresSafeArea()
    }
}

#Preview("On camera feed") {
    WrongGearCountLayer(issue: .tooFew, onFixed: {})
        .previewBackdrop(.cameraFeed)
}

#Preview("On parchment") {
    WrongGearCountLayer(issue: .tooMany(3), onFixed: {})
        .previewBackdrop(.parchment)
}
