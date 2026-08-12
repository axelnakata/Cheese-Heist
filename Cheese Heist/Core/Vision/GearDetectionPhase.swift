//
//  GearDetectionPhase.swift
//  Cheese Heist
//
//  Where the detection pipeline is. Distinct from `Level1Phase`: this is the
//  detector's own lifecycle, and Level 1 observes it rather than driving it.
//

enum GearDetectionPhase: Equatable, Sendable {
    case idle
    case searching
    /// Committed to a pair of gears. Tracking continues — see `GearDetectionService`.
    case locked
    case timedOut(GearDetectionFailure)
    case unavailable(GearDetectionFailure)

    var isLocked: Bool { self == .locked }

    var failure: GearDetectionFailure? {
        switch self {
        case .timedOut(let failure), .unavailable(let failure): return failure
        case .idle, .searching, .locked: return nil
        }
    }
}
