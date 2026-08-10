//
//  MouseSprite.swift
//  Cheese Heist
//
//  Which pose the mouse is wearing.
//
//  The three in-scene poses share ONE trimmed bounding box (PRD-Level1 §5.2), so
//  swapping between them changes only the pixels — the sprite stays registered and the
//  mouse does not jump when it starts struggling. `happy` is the success screen's own
//  artwork and is never used in the scene.
//

import CoreGraphics

enum MouseSprite: String, CaseIterable, Sendable {
    case talkIdle = "mouse_talk_idle"
    case talkStruggle = "mouse_talk_struggle"
    case shockHappy = "mouse_shock_happy"
    case happy = "mice_happy"

    var assetName: String { rawValue }

    /// The shared trim's aspect ratio, width over height. All three in-scene poses have
    /// it by construction; `happy` is trimmed on its own and carries its own.
    var aspectRatio: CGFloat {
        switch self {
        case .talkIdle, .talkStruggle, .shockHappy: return 881.0 / 1200.0
        case .happy: return 1004.0 / 1200.0
        }
    }

    /// Poses the mouse can wear while standing in the AR scene.
    static let inScene: [MouseSprite] = [.talkIdle, .talkStruggle, .shockHappy]
}
