//
//  MouseSprite.swift
//  Cheese Heist
//
//  Which 2D mouse portrait is showing — dialogue bubbles and the result screen. The
//  in-scene AR mouse is `MouseModelEntity`, a 3D rig with no per-pose art of its own;
//  see `GameplaySceneCoordinator+Update.swift.setMousePose` for why these poses no
//  longer reach it.
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
}
