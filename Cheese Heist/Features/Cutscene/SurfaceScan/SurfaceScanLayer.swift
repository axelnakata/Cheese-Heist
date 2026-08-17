//
//  SurfaceScanLayer.swift
//  Cheese Heist
//
//  PRD-Cutscene §6.1 — the scanning overlay: position guideline strip at the top,
//  invalid mark at centre when the surface is bad, and the instruction chip at the
//  bottom. The green ring is a 3D entity, not a SwiftUI layer.
//
//  Layout is from `Docs/cutscene frames/cutscene guidelines.png` (valid) and
//  `cutscene guidelines - Fall Back.png` (invalid).
//


import SwiftUI

struct SurfaceScanLayer: View {

    let validity: SurfaceValidity
    let isTappable: Bool
    let onTap: () -> Void

    @Environment(\.layoutScale) private var scale

    var body: some View {
        ZStack {
            if isTappable {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onTap)
            }

            RecommendedPositionStrip()

            VStack {
                Spacer()
                chip
                    .padding(.bottom, AppSpacing.xxl * scale)
            }
        }
    }

    @ViewBuilder
    private var chip: some View {
        if validity == .valid {
            InstructionChip(CutsceneScript.scanValid)
        } else {
            InstructionChip(CutsceneScript.scanInvalid)
        }
    }
}

#Preview("Valid surface") {
    SurfaceScanLayer(validity: .valid, isTappable: true, onTap: {})
        .previewBackdrop(.cameraFeed)
}

#Preview("Invalid — no surface") {
    SurfaceScanLayer(validity: .noSurface, isTappable: false, onTap: {})
        .previewBackdrop(.cameraFeed)
}

#Preview("Invalid — too small") {
    SurfaceScanLayer(validity: .tooSmall, isTappable: false, onTap: {})
        .previewBackdrop(.parchment)
}
