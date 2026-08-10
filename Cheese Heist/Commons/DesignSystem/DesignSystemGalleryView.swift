//
//  DesignSystemGalleryView.swift
//  Cheese Heist
//
//  Every token and component on one screen. It is the app's temporary root so that a
//  build to device proves the fonts actually registered — risk R-07 is invisible in a
//  simulator preview that happens to have the font installed system-wide.
//
//  WS-2 replaces this as the root; keep the view, it stays useful as a reference.
//

import SwiftUI

struct DesignSystemGalleryView: View {

    private static let swatches: [(name: String, color: Color)] = [
        ("accent", AppColor.accent),
        ("surfaceBlueprint", AppColor.surfaceBlueprint),
        ("roleDriver", AppColor.roleDriver),
        ("roleFollower", AppColor.roleFollower),
        ("stateValid", AppColor.stateValid),
        ("stateInvalid", AppColor.stateInvalid),
        ("surfaceBackground", AppColor.surfaceBackground)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                typeSpecimen
                colourSwatches
                components
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.xl)
        }
        .background(AppColor.surfaceBackground)
    }

    private var typeSpecimen: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("Cheese Heist").appText(AppFont.largeTitle)
            Text("Title — Nunito ExtraBold").appText(AppFont.title)
            Text("Subtitle — Nunito Bold").appText(AppFont.subtitle)
            Text("Body — Nunito Regular").appText(AppFont.body)
            Text("Dialogue — Nunito Regular 24").appText(AppFont.dialogue)
        }
        .foregroundStyle(AppColor.textPrimary)
    }

    private var colourSwatches: some View {
        HStack(spacing: AppSpacing.s) {
            ForEach(Self.swatches, id: \.name) { swatch in
                VStack(spacing: AppSpacing.xs) {
                    RoundedRectangle(cornerRadius: AppSpacing.xs, style: .continuous)
                        .fill(swatch.color)
                        .frame(width: 96, height: 96)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.xs, style: .continuous)
                                .strokeBorder(AppColor.textPrimary.opacity(0.15))
                        )
                    Text(swatch.name)
                        .appText(AppFont.body)
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
        }
    }

    private var components: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            HStack(spacing: AppSpacing.m) {
                PrimaryButton(title: "Play") {}
                ForEach(LargeCTAButtonIcon.allCases, id: \.self) { icon in
                    LargeCTAButton(icon: icon) {}
                }
            }
            InstructionChip(["Find a flat surface.", "Tap on the green circle to start!"])
            SpeechBubbleView(text: PreviewDialogue.craneCompliment)
            TapToContinueHint()
                .foregroundStyle(AppColor.textPrimary)
        }
    }
}

#Preview {
    DesignSystemGalleryView()
        .providesLayoutScale()
}
