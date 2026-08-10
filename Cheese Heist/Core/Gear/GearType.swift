// GearType.swift — Cheese Heist
// PRD §6.1 — LEGO Technic spur gears, module 1.0 mm.

import Foundation

enum GearType: Int, CaseIterable, Hashable, Codable, Sendable {
    case eightTooth = 8
    case twentyFourTooth = 24
    case fortyTooth = 40

    var teeth: Int { rawValue }

    /// Module 1.0: pitch diameter in mm equals tooth count.
    var pitchRadiusMetres: Double { Double(teeth) * 0.0005 }

    /// Tip radius (pitch radius + 1 module), for collision and placement.
    var tipRadiusMetres: Double { Double(teeth + 2) * 0.0005 }

    /// USDZ asset name in Resources/3DModels/Gears/.
    var modelName: String {
        switch self {
        case .eightTooth:      return "gear_8t"
        case .twentyFourTooth: return "gear_24t"
        case .fortyTooth:      return "gear_40t"
        }
    }

    /// Module-1 meshing centre distance between two gears, in metres.
    static func meshDistance(_ lhs: GearType, _ rhs: GearType) -> Double {
        (lhs.pitchRadiusMetres + rhs.pitchRadiusMetres)
    }
}
