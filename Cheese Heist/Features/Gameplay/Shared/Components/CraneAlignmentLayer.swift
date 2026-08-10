//
//  CraneAlignmentLayer.swift
//  Cheese Heist
//
//  Phase 1: a full-screen scrim, a plain white title, and the line-art of hands holding
//  an iPad over a crane.
//
//  THE TITLE IS BARE TEXT, NOT AN INSTRUCTION CHIP. This is the only screen in Level 1
//  where that is true, and it is deliberate: the chip is the app talking over a live
//  scene, and here there is no scene yet — the camera is dimmed almost to black and the
//  illustration IS the screen. A navy chip floating over it reads as a second, competing
//  panel. `Level1PhasePresentation.chip(for:)` returns nil for this phase so the two
//  cannot both appear.
//
//  IT HAS NO TAP TARGET. The illustration comes down when the DETECTOR can see gears
//  (`DetectionViabilityGate`), not when the child taps — tapping past it would leave
//  them detecting from a viewpoint the model cannot work with, and the failure would
//  show up twelve seconds later as a timeout with no obvious cause.
//
//  It is an illustration, not a reticle. Parent PRD §11.5.1 specifies a reticle with a
//  plane/distance/stillness gate; §10 of the Level 1 PRD amends that away.
//

import SwiftUI

struct CraneAlignmentLayer: View {

    /// Passed in, never read from a level's script: Level 2 aligns a crane too and
    /// only the copy differs, so the copy is a parameter (PRD-Level1 §9.1).
    let title: String

    @Environment(\.layoutScale) private var scale

    /// Title and artwork are one centred stack, which lands the title around a seventh
    /// of the way down and the artwork just below centre — the frame's proportions,
    /// without either being pinned to an edge that changes between the 11" and 12.9".
    private enum Metric {
        static let titleGap: CGFloat = 40
        static let sideMargin: CGFloat = 60
    }

    var body: some View {
        ZStack {
            ScrimOverlay()

            VStack(spacing: Metric.titleGap * scale) {
                Text(title)
                    .appText(AppFont.largeTitle)
                    .foregroundStyle(AppColor.textOnCamera)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                CraneAlignmentIllustration()
            }
            .padding(.horizontal, Metric.sideMargin * scale)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    CraneAlignmentLayer(title: "Put your crane on the center of the camera")
        .previewBackdrop(.cameraFeed)
}
