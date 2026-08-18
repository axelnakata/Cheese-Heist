//
//  LevelSelectModel.swift
//  Cheese Heist
//
//  Figma "Little Einstein Board" 431:92 — the level-select path. A stop is either the
//  numbered marker for an unlocked level, the mouse's current position, or a locked
//  level waiting to be unlocked. Kept separate from `AppRoute` on purpose: which level
//  number maps to which route is still undecided, so this model only describes what the
//  path looks like, not where "Play" goes.
//

import Foundation

struct LevelSelectStop: Identifiable {

    enum Kind {
        case marker(number: Int)
        case current
        case locked
    }

    let id: Int
    let kind: Kind
}

enum LevelSelectPath {

    /// One unlocked level (its marker + the mouse standing on it) followed by four
    /// locked levels, matching the six path stops in the Figma frame.
    static let stops: [LevelSelectStop] = [
        LevelSelectStop(id: 0, kind: .marker(number: 1)),
        LevelSelectStop(id: 1, kind: .current),
        LevelSelectStop(id: 2, kind: .locked),
        LevelSelectStop(id: 3, kind: .locked),
        LevelSelectStop(id: 4, kind: .locked),
        LevelSelectStop(id: 5, kind: .locked)
    ]
}
