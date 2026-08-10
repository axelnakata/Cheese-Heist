//
//  GearDetectionFailure.swift
//  Cheese Heist
//
//  Why detection gave up, so the fallback sheet can say something specific instead of
//  "failed".
//

import Foundation

enum GearDetectionFailure: Equatable, Sendable {
    case modelUnavailable(String)
    case noGears
    case tooFew
    case tooMany(Int)
    case noDepth

    var title: String {
        switch self {
        case .modelUnavailable: return "Gear detection unavailable"
        case .noGears:          return "No gears detected"
        case .tooFew:           return "Only one gear found"
        case .tooMany:          return "Too many gears"
        case .noDepth:          return "Can't measure distance"
        }
    }

    var advice: String {
        switch self {
        case .modelUnavailable(let reason):
            return reason
        case .noGears:
            return "Point the iPad at the crane so the gears are in the middle of "
                 + "the screen, about an arm's length away."
        case .tooFew:
            return "This needs two gears that touch each other. Move so both gears "
                 + "are in view."
        case .tooMany(let count):
            return "I can see \(count) gears, but this needs exactly two. Move the "
                 + "extra gears out of view."
        case .noDepth:
            return "I can see the gears but I can't measure how far away they are. "
                 + "Move a little closer, so the bigger gear fills more of the screen."
        }
    }
}
