//
//  LargeCTAButtonIcon.swift
//  Cheese Heist
//
//  PRD §7.6 — the icon-only CTA's variants. An enum rather than a raw SF Symbol string
//  so a call site cannot invent a sixth button.
//

enum LargeCTAButtonIcon: String, CaseIterable {
    case next
    case back
    case retry
    case home
    case info
    case cutscene

    var systemName: String {
        switch self {
        case .next: "arrow.right"
        case .back: "arrow.left"
        case .retry: "arrow.counterclockwise"
        case .home: "house.fill"
        case .info: "info.circle"
        case .cutscene: "movieclapper.fill"
        }
    }

    /// Spoken by VoiceOver and used as the button's accessibility label.
    var accessibilityLabel: String {
        switch self {
        case .next: "Next"
        case .back: "Back"
        case .retry: "Try again"
        case .home: "Home"
        case .info: "More information"
        case .cutscene: "Watch cutscene again"
        }
    }
}
