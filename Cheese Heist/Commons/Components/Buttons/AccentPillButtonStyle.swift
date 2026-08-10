//
//  AccentPillButtonStyle.swift
//  Cheese Heist
//
//  PRD §7.6 — the fill, stroke and press behaviour shared by PrimaryButton and
//  LargeCTAButton. Extracted so the two buttons cannot drift apart.
//

import SwiftUI

struct AccentPillButtonStyle: ButtonStyle {

    @Environment(\.layoutScale) private var scale

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: AppRadius.pill * scale, style: .continuous)

        return configuration.label
            .background(configuration.isPressed ? AppColor.accentPressed : AppColor.accent, in: shape)
            .overlay(shape.strokeBorder(AppColor.accentStroke, lineWidth: AppStroke.button * scale))
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
