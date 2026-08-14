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
//  THERE IS NO MANUAL CHOICE. It used to let the child tap out which two gears they
//  built with, but that answer can lie — Level 1 and Level 2 both read tooth counts
//  from the DETECTOR, and a picked pair that doesn't match what the camera can see
//  breaks the one invariant the physics depends on. "Try looking again" is the only way
//  forward, and it is also the fix for nearly every failure listed here (bad framing,
//  bad lighting, gears out of view).
//

import SwiftUI

struct DetectionManualFallbackSheet: View {

    let failure: GearDetectionFailure
    let onRetry: () -> Void

    @Environment(\.layoutScale) private var scale

    var body: some View {
        VStack(spacing: AppSpacing.l * scale) {
            Text(failure.title)
                .appText(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)

            Text(failure.advice)
                .appText(AppFont.body)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)

            PrimaryButton(title: "Try looking again", action: onRetry)
        }
        .padding(AppSpacing.xl * scale)
        .background(AppColor.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip * scale))
    }
}
