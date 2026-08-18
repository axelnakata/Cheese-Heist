//
//  LevelSelectViewModel.swift
//  Cheese Heist
//
//  Presentation and selection state for the level-select path. Manages the active
//  `.current` stop, audio feedback, and provides the route for the "Play" action.
//

import Observation

@Observable
final class LevelSelectViewModel {

    private(set) var stops: [LevelSelectStop]
    private(set) var selectedStopID: Int

    var selectedRoute: AppRoute {
        stops.first(where: { $0.id == selectedStopID })?.route ?? .level1
    }

    init(stops: [LevelSelectStop] = LevelSelectPath.defaultStops) {
        self.stops = stops
        if let currentStop = stops.first(where: { $0.kind == .current }) {
            self.selectedStopID = currentStop.id
        } else {
            self.selectedStopID = stops.first?.id ?? 0
        }
    }

    /// Selects an unlocked stop, making it `.current` and reverting the previous
    /// current stop back to its numbered marker.
    @discardableResult
    func selectStop(_ stop: LevelSelectStop) -> Bool {
        selectStop(id: stop.id)
    }

    @discardableResult
    func selectStop(id: Int) -> Bool {
        guard let targetIndex = stops.firstIndex(where: { $0.id == id }) else {
            return false
        }
        let targetStop = stops[targetIndex]

        guard targetStop.kind != .locked else {
            return false
        }

        guard selectedStopID != id else {
            return false
        }

        if let previousIndex = stops.firstIndex(where: { $0.id == selectedStopID }) {
            let previousStop = stops[previousIndex]
            if previousStop.kind == .current {
                stops[previousIndex].kind = .marker(number: previousStop.levelNumber)
            }
        }

        stops[targetIndex].kind = .current
        selectedStopID = id
        AudioManager.shared.playSFX(.tap1)
        return true
    }
}
