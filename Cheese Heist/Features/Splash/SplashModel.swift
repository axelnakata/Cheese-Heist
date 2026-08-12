//
//  SplashModel.swift
//  Cheese Heist
//
//  PRD §11.1 — the logo asset name and tagline, as data rather than a literal in
//  `SplashLogoView`, so a Level-2 reskin swaps the wordmark without touching the view.
//

struct SplashModel {
    let logoAssetName: String
    let tapToPlayText: String

    static let level1 = SplashModel(logoAssetName: "logo_title", tapToPlayText: "Tap to play")
}
