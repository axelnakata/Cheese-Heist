//
//  Level2ViewModel+Presentation.swift
//  Cheese Heist
//
//  Presentation computed properties for Level 2 ViewModel.
//

import Foundation
import CoreGraphics

extension Level2ViewModel {

    var screenTargets: [GearScreenTarget] { scene?.screenTargets ?? [] }
    var mouseAnchor: CGPoint? { scene?.mouseScreenAnchor }
    var chipText: String? { Level2PhasePresentation.chip(for: phase) }
    var isResult: Bool { Level2PhasePresentation.isResult(phase) }
    var liftProgress: Double { runner?.progress ?? 0 }
    var crankHint: CrankHint {
        .of(drive: crank.drive, isPressed: crank.isPressed, hasElevation: (runner?.state.height ?? 0) > 0)
    }
    var showsBars: Bool { Level2PhasePresentation.showsBars(phase) }
    var showsTimer: Bool { Level2PhasePresentation.showsTimer(phase) }
    var showsCheeseCountdown: Bool { Level2PhasePresentation.showsCheeseCountdown(phase) }
    var showsRoleLabels: Bool { Level2PhasePresentation.showsRoleLabels(phase) }
    var showsJoystick: Bool { Level2PhasePresentation.showsJoystick(phase) }

    /// The strength bar level for the current gear combination, or 0 if no outcome yet.
    var strengthLevel: Int { outcome?.strengthLevel ?? 0 }

    /// The speed bar level for the current gear combination, or 0 if no outcome yet.
    var speedLevel: Int { outcome?.speedLevel ?? 0 }

    /// Whether the current result is a fail (weak or slow).
    var isFail: Bool {
        phase == .failedWeak || phase == .failedSlow
    }

    /// Whether the fail is a "weak" fail (stall) vs "slow" fail (timeout).
    var isWeakFail: Bool {
        phase == .failedWeak
    }

    /// The result screen copy.
    var resultCopy: (title: String, subtitle: String) {
        Level2Script.resultCopy(
            stars: isFail ? 0 : starCount,
            isFail: isFail,
            isWeak: isWeakFail
        )
    }

    /// The mouse sprite for the result screen. Both fail reasons (weak and slow) share
    /// the same "fleeing the cat" scene — only the title/subtitle differ.
    var resultMouseSprite: String {
        if isFail {
            return MouseSprite.fail.assetName
        }
        switch resultStarCount {
        case 3:
            return MouseSprite.threestars.assetName
        case 2:
            return MouseSprite.twostars.assetName
        default:
            return MouseSprite.onestar.assetName
        }
    }

    /// Final star count for the result screen.
    var resultStarCount: Int {
        isFail ? 0 : starCount
    }

    func playMainAudio() {
        AudioManager.shared.playBGM(.page1)
    }
}
