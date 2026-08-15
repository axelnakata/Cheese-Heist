//
//  MouseSprite.swift
//  Cheese Heist
//
//  Which pose the mouse is wearing.
//
//  `happy` is the pose Level 1 wears throughout — see `Level1SceneDirector.mousePose`.
//  The other three are trimmed to ONE shared bounding box (PRD-Level1 §5.2) so that
//  swapping between them changes only the pixels; `happy` was trimmed on its own and
//  carries a different aspect ratio, which is why `MouseSpriteEntity` rebuilds its quad
//  on a pose change rather than only re-texturing it.
//

import CoreGraphics

enum MouseSprite: String, CaseIterable, Sendable {
//    case talkIdle = "Mouse_default"
    case talkStruggle = "Mouse_struggle"
    case amazed = "Mouse_amazed"
    case happy = "Mouse_default"
    case think = "Mouse_thinking"
    case threestars = "Mouse_3star"
    case twostars = "Mouse_2star"
    case onestar = "Mouse_1star"
    case zerostar = "Mouse_0star"
    
//    case afk = "Mouse_peeking"

    var assetName: String { rawValue }

    /// The trim's aspect ratio, width over height, straight off the PNG's pixel size.
    var aspectRatio: CGFloat {
        switch self {
        case .talkStruggle, .amazed: return 881.0 / 1200.0
        case .happy: return 1004.0 / 1200.0
        // Re-cut from `mouse think 1.svg`'s 4096 × 3413 raster to the same 1200 px
        // height as the other four. The first import was the SVG's own crop — the mouse
        // sliced off at the waist and shoved into a landscape box.
        case .think: return 1003.0 / 1200.0
        // Result-screen-only poses: never enter `inScene`, so `MouseSpriteEntity`
        // never queries this for them. `SuccessOverlay` sizes them with
        // `.scaledToFit()` off the PNG's own intrinsic ratio instead.
        case .threestars, .twostars, .onestar, .zerostar: return 1.0
        }
    }

    /// Poses the mouse can wear while standing in the AR scene.
    static let inScene: [MouseSprite] = [.happy, .talkStruggle, .amazed]
}
