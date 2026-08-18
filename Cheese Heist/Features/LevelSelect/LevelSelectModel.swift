//
//  LevelSelectModel.swift
//  Cheese Heist
//
//  Figma "Little Einstein Board" 431:92 — the level-select path. A stop is either the
//  numbered marker for an unlocked level, the mouse's current position, or a locked
//  level waiting to be unlocked.
//

import Foundation

struct LevelSelectStop: Identifiable, Equatable {

    enum Kind: Equatable {
        case marker(number: Int)
        case current
        case locked
    }

    let id: Int
    let levelNumber: Int
    var kind: Kind
    let route: AppRoute?

    init(id: Int, levelNumber: Int? = nil, kind: Kind, route: AppRoute? = nil) {
        self.id = id
        self.levelNumber = levelNumber ?? (id + 1)
        self.kind = kind
        self.route = route
    }
}

enum LevelSelectPath {

    /// One unlocked level (its marker + the mouse standing on it) followed by four
    /// locked levels, matching the six path stops in the Figma frame.
    static let defaultStops: [LevelSelectStop] = [
        LevelSelectStop(id: 0, levelNumber: 1, kind: .marker(number: 1), route: .level1),
        LevelSelectStop(id: 1, levelNumber: 2, kind: .current, route: .level2),
        LevelSelectStop(id: 2, levelNumber: 3, kind: .locked, route: nil),
        LevelSelectStop(id: 3, levelNumber: 4, kind: .locked, route: nil),
        LevelSelectStop(id: 4, levelNumber: 5, kind: .locked, route: nil),
        LevelSelectStop(id: 5, levelNumber: 6, kind: .locked, route: nil)
    ]

    static var stops: [LevelSelectStop] { defaultStops }
}
