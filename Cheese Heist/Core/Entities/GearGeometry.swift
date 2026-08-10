//
//  GearGeometry.swift
//  Cheese Heist
//
//  LEGO Technic module-1 dimensions, in metres. This is the authority a loaded model
//  is measured against — never the other way round.
//
//  Module 1 means the pitch diameter in millimetres simply equals the tooth count: an
//  8T gear is 8mm across the pitch circle, a 40T is 40mm. Everything else follows.
//

import Foundation

enum GearGeometry {

    /// One module, in metres.
    static let module: Float = 0.001

    /// Pitch radius — where two meshed gears touch.
    static func pitchRadius(teeth: Int) -> Float {
        Float(teeth) * module / 2
    }

    /// Outer (tip) radius — what the gear actually measures across.
    /// Addendum is one module.
    static func tipRadius(teeth: Int) -> Float {
        pitchRadius(teeth: teeth) + module
    }

    static func tipDiameter(teeth: Int) -> Float {
        tipRadius(teeth: teeth) * 2
    }

    /// Meshing centre distance between two gears: the tooth sum, halved, in mm.
    /// 24mm for an 8T against a 40T.
    static func centreDistance(_ first: Int, _ second: Int) -> Float {
        Float(first + second) * module / 2
    }

    static func tipRadius(of type: GearType) -> Float { tipRadius(teeth: type.teeth) }
    static func centreDistance(_ pair: GearPair) -> Float {
        centreDistance(pair.driver.teeth, pair.follower.teeth)
    }
}
