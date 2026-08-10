//
//  View+LayoutScale.swift
//  Cheese Heist
//
//  PRD §7.4 — measures the container once and publishes the scale factor. Applied at
//  the app root only; nothing below it ever measures again.
//

import SwiftUI

private struct LayoutScaleProvider: ViewModifier {

    func body(content: Content) -> some View {
        GeometryReader { proxy in
            content
                .frame(width: proxy.size.width, height: proxy.size.height)
                .environment(\.layoutScale, LayoutScale.factor(forWidth: proxy.size.width))
        }
    }
}

extension View {

    /// Publishes `\.layoutScale` for this view and everything beneath it.
    ///
    /// Wraps in a `GeometryReader`, so apply it once at the root — not per screen.
    func providesLayoutScale() -> some View {
        modifier(LayoutScaleProvider())
    }
}
