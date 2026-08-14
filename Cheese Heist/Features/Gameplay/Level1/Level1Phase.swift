//
//  Level1Phase.swift
//  Cheese Heist
//
//  The Level 1 flow, PRD-Level1 §3 and §8.
//
//  `confirmingDetection` from the parent PRD §10.3 is gone (D-4: twins appear
//  immediately on lock). `manualFallback` replaces it as a TIMEOUT-ONLY branch.
//
//  The guided teaching run (intro/teachingDriver/teachingJoystick/guidedCrank/
//  teachingFollower/handOver) is gone too — the flow now mirrors Level 2's shorter
//  shape: pick a driver, get shown once what driver/follower mean while the joystick
//  is already live, then free-run. `selectingRoles` is the plain-gears pick;
//  `rolesChosen` is the same phase Level 2 uses for "roles picked, joystick armed,
//  still swappable" — see `Level1PhaseMachine`.
//

enum Level1Phase: String, CaseIterable, Equatable, Sendable {
    case aligningCrane
    case detectingGears
    case manualFallback
    case selectingRoles
    case rolesChosen
    case freeCrank
    case succeeded

    /// How far up this phase is allowed to lift, or nil if it does not lift at all.
    var liftSegment: LiftSegment? {
        switch self {
        case .freeCrank: return .full
        default: return nil
        }
    }
}
