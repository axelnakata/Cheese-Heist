//
//  GearPairVote.swift
//  Cheese Heist
//
//  Temporal agreement on the tooth counts, before anything commits to them.
//
//  A single frame's detection is not enough to act on. Motion blur, an unlucky angle
//  or a momentary occlusion can produce a confident-but-wrong tooth count, and the
//  whole downstream simulation is built on that number.
//
//  CONSECUTIVE, not "most popular recently". A lock should mean "these two gears,
//  steadily", not "these two gears, eventually" — so a disagreeing frame clears the
//  streak rather than being outvoted by its neighbours.
//
//  Three frames, not five. This only has to reject the occasional single-frame
//  misclassification between visibly different gears; every remaining source of error
//  is fixed by tracking, not by making the child hold still for longer.
//

import Foundation

struct GearPairVote: Equatable, Sendable {

    static let framesToLock = 3

    private(set) var streak = 0
    private var current: [Int] = []

    /// Records one frame's opinion. Returns the settled pair once the streak is long
    /// enough, and nil until then.
    @discardableResult
    mutating func submit(_ pair: (GearType, GearType)) -> (GearType, GearType)? {
        let sorted = [pair.0.teeth, pair.1.teeth].sorted()
        if current != sorted {
            current = sorted
            streak = 0
        }
        streak += 1
        return consensus
    }

    /// The settled pair, smaller gear first, or nil while the vote is still running.
    var consensus: (GearType, GearType)? {
        guard streak >= Self.framesToLock, current.count == 2,
              let low = GearType(rawValue: current[0]),
              let high = GearType(rawValue: current[1]) else { return nil }
        return (low, high)
    }

    /// 0…1 progress toward a settled pair, for the on-screen indicator.
    var progress: Double {
        min(1, Double(streak) / Double(Self.framesToLock))
    }

    /// A frame that did not show exactly two gears breaks the streak.
    mutating func reset() {
        streak = 0
        current = []
    }
}
