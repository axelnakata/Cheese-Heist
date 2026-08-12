//
//  DetectionViabilityGate.swift
//  Cheese Heist
//
//  Decides when the alignment illustration can come down.
//
//  This replaces the parent PRD §11.5.1 reticle, which gated on a plane being found,
//  a distance band and a stillness test — three proxies for the question that actually
//  matters, which is whether the model can see the gears. Asking the detector directly
//  is both shorter and strictly more relevant: a child holding the iPad perfectly
//  still at exactly 40cm, pointed at the wrong end of the table, passed every proxy
//  and could not be detected.
//
//  Consecutive frames, for the same reason `GearPairVote` counts consecutively — a
//  single lucky frame is not evidence that the crane is framed.
//

import Foundation

struct DetectionViabilityGate: Equatable, Sendable {

    /// Frames in a row that must show at least one gear. At the 6 Hz detection rate
    /// this is about a third of a second — long enough that a glancing pass across
    /// the crane does not trip it, short enough that a child who has framed the crane
    /// does not notice waiting.
    static let framesToPass = 2

    private(set) var streak = 0
    private(set) var isViable = false

    /// One detection tick. Returns true on the update that first passes the gate, so
    /// the caller can fire its event exactly once.
    @discardableResult
    mutating func observe(gearCount: Int) -> Bool {
        guard !isViable else { return false }

        guard gearCount > 0 else {
            streak = 0
            return false
        }

        streak += 1
        guard streak >= Self.framesToPass else { return false }

        isViable = true
        return true
    }

    mutating func reset() {
        streak = 0
        isViable = false
    }
}
