//
//  TextStyle.swift
//  Cheese Heist
//
//  PRD §7.3 — everything a label needs to render. Split from `AppFont` per the
//  one-type-per-file rule (PRD §8.4).
//

import CoreGraphics

struct TextStyle: Equatable {
    /// PostScript name, as registered through `UIAppFonts`.
    let fontName: String
    let size: CGFloat
    /// Design line height. Converted to additive `lineSpacing` by `View.appText(_:)`.
    let lineHeight: CGFloat
    let tracking: CGFloat
}
