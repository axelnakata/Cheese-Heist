//
//  AccentPillButtonStyle.swift
//  Cheese Heist
//
//  PRD §7.6 — the fill, stroke and press behaviour shared by PrimaryButton and
//  LargeCTAButton. Extracted so the two buttons cannot drift apart.
//

import SwiftUI

struct AccentPillButtonStyle: ButtonStyle {

    /// Design-scale corner radius. The §7.5 pill suits every control built to the
    /// standard button height; `LargeCTAButton` passes its own, because that token stops
    /// reading as a capsule once the button is larger than twice it.
    var cornerRadius: CGFloat = AppRadius.pill
    var fillColor: Color = AppColor.accent
    var pressedFillColor: Color = AppColor.accentPressed

    @Environment(\.layoutScale) private var scale

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius * scale, style: .continuous)

        return configuration.label
            .background(configuration.isPressed ? pressedFillColor : fillColor, in: shape)
            .overlay(shape.strokeBorder(AppColor.accentStroke, lineWidth: AppStroke.button * scale))
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
