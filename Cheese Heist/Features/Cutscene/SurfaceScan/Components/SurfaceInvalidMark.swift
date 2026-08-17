////
////  SurfaceInvalidMark.swift
////  Cheese Heist
////
////  The red ✗ shown at screen centre when the detected surface is not valid.
////  Rendered from `surface_invalid.png` — the paint-stroke cross from Figma.
////
//
//import SwiftUI
//
//struct SurfaceInvalidMark: View {
//
//    @Environment(\.layoutScale) private var scale
//
//    private enum Metric {
//        /// Figma frame `cutscene guidelines - Fall Back` (522:208).
//        static let width: CGFloat = 498
//    }
//
//    var body: some View {
//        Image("surface_invalid")
//            .resizable()
//            .scaledToFit()
//            .frame(width: Metric.width * scale)
//            .allowsHitTesting(false)
//    }
//}
//
//#Preview("Camera feed") {
//    SurfaceInvalidMark()
//        .previewBackdrop(.cameraFeed)
//}
//
//#Preview("Parchment") {
//    SurfaceInvalidMark()
//        .previewBackdrop(.parchment)
//}
