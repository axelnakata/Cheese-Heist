//
//  DetectionManualFallbackSheet.swift
//  Cheese Heist
//
//  The timeout-only branch (D-4). There is no confirm step in the happy path — twins
//  appear the moment detection locks — so this is the ONLY place the child is ever
//  asked what gears they built with, and it appears only after twelve seconds of the
//  model not managing it.
//
//  It says what went wrong specifically. "Detection failed" tells a child nothing they
//  can act on; "I can see 3 gears, but this needs exactly 2" tells them what to do.
//

import SwiftUI

struct DetectionManualFallbackSheet: View {

    let failure: GearDetectionFailure
    let onChoose: (GearType, GearType) -> Void
    let onRetry: () -> Void

    @Environment(\.layoutScale) private var scale
    @State private var first: GearType?
    @State private var second: GearType?

    var body: some View {
        VStack(spacing: AppSpacing.l * scale) {
            Text(failure.title)
                .appText(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)

            Text(failure.advice)
                .appText(AppFont.body)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)

            Text("Or tell me which two gears you used:")
                .appText(AppFont.body)
                .foregroundStyle(AppColor.textPrimary)

            HStack(spacing: AppSpacing.m * scale) {
                ForEach(GearType.allCases, id: \.self) { type in
                    gearCard(type)
                }
            }

            PrimaryButton(title: "Try looking again", action: onRetry)
        }
        .padding(AppSpacing.xl * scale)
        .background(AppColor.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip * scale))
    }

    private func gearCard(_ type: GearType) -> some View {
        Button {
            choose(type)
        } label: {
            VStack(spacing: AppSpacing.xs * scale) {
                Text("\(type.teeth)")
                    .appText(AppFont.title)
                Text("teeth")
                    .appText(AppFont.body)
            }
            .foregroundStyle(AppColor.textPrimary)
            .frame(width: 120 * scale, height: 120 * scale)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.chip * scale)
                    .fill(AppColor.accent.opacity(selectionOpacity(for: type)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.chip * scale)
                    .strokeBorder(AppColor.accentStroke, lineWidth: AppStroke.button * scale)
            )
        }
    }

    /// First tap picks one gear, second tap picks the other and commits. Tapping the
    /// same card twice is legal — two 24T gears is a real build.
    private func choose(_ type: GearType) {
        guard let first else {
            first = type
            return
        }
        second = type
        onChoose(first, type)
    }

    private func selectionOpacity(for type: GearType) -> Double {
        (first == type || second == type) ? 1 : 0.25
    }
}
