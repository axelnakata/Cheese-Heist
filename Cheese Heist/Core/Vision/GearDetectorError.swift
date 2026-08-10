//
//  GearDetectorError.swift
//  Cheese Heist
//

import Foundation

enum GearDetectorError: LocalizedError {
    case modelNotFound
    case modelLoadFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "GearDetectorModel.mlpackage is not in the app bundle. "
                 + "Copy it into Resources/ML/ keeping that exact filename."
        case .modelLoadFailed(let reason):
            return "Could not load the gear model: \(reason)"
        }
    }
}
