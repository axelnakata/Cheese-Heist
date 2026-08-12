//
//  Level1Phase.swift
//  Cheese Heist
//
//  The Level 1 flow, PRD-Level1 §3 and §8.
//
//  `confirmingDetection` from the parent PRD §10.3 is gone (D-4: twins appear
//  immediately on lock). `manualFallback` replaces it as a TIMEOUT-ONLY branch, and
//  `selectingDriver` splits into `handOver` — the instruction beat — and
//  `selectingRoles`, the interaction. Splitting them is what lets the cheese drop back
//  to the table while the child is still reading, rather than as they reach for a gear.
//

enum Level1Phase: String, CaseIterable, Equatable, Sendable {
    case aligningCrane
    case detectingGears
    case manualFallback
    case introDialogue
    case teachingDriver
    case teachingJoystick
    case guidedCrankToHalf
    case teachingFollower
    case guidedCrankToFull
    case handOver
    case selectingRoles
    case freeCrank
    case succeeded

    /// How far up this phase is allowed to lift, or nil if it does not lift at all.
    ///
    /// THE ONLY PLACE "guided" AND "free" DIFFER. `Core/Gear` has no concept of either
    /// and contains no phase-shaped branch; it receives a `Double` and integrates
    /// against it. The free run is the identical code path as the guided run.
    var liftSegment: LiftSegment? {
        switch self {
        case .guidedCrankToHalf: return .half
        case .guidedCrankToFull, .freeCrank: return .full
        default: return nil
        }
    }
}
