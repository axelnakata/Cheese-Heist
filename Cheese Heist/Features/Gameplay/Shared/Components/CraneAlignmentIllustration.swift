//
//  CraneAlignmentIllustration.swift
//  Cheese Heist
//
//  The white line-art of two hands holding an iPad over a crane.
//
//  It is an ILLUSTRATION, not a reticle — nothing here is measured against the camera
//  and nothing lines up with the real crane. It says "hold it like this", and the
//  detector decides when that has worked (`DetectionViabilityGate`).
//
//  The Figma export is an SVG, but only nominally: it is two base64 PNGs placed through
//  `<pattern>` fills, which Xcode's asset-catalog SVG renderer ignores completely —
//  the image loaded, drew nothing, and left the screen blank. The asset is therefore
//  flattened to a PNG at 3x, composed with the SVG's own transforms.
//

import SwiftUI

struct CraneAlignmentIllustration: View {

    @Environment(\.layoutScale) private var scale

    /// The artwork's own Figma dimensions.
    private enum Metric {
        static let width: CGFloat = 886
        static let height: CGFloat = 651
    }

    var body: some View {
        Image("crane_guidance")
            .resizable()
            .scaledToFit()
            .frame(width: Metric.width * scale, height: Metric.height * scale)
            .accessibilityLabel("Hands holding an iPad above a LEGO crane")
    }
}

#Preview {
    CraneAlignmentIllustration()
        .previewBackdrop(.cameraFeed)
}
