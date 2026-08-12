// Logger+Categories.swift — Cheese Heist
// Structured logging categories replacing gear-poc's print statements.

import os
import Foundation

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "CheeseHeist"

    static let arSession = Logger(subsystem: subsystem, category: "ARSession")
    static let detection = Logger(subsystem: subsystem, category: "Detection")
    static let crane     = Logger(subsystem: subsystem, category: "Crane")
    static let scene     = Logger(subsystem: subsystem, category: "Scene")
    static let gameplay  = Logger(subsystem: subsystem, category: "Gameplay")
    static let cutscene  = Logger(subsystem: subsystem, category: "Cutscene")
}
