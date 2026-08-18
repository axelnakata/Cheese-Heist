//
//  LevelSelectViewModelTests.swift
//  CheeseHeistTests
//
//  Level select state: stop selection, updating tapped stop to .current, reverting
//  previous stop to .marker, and resolving the destination route for "Play".
//

import Testing
@testable import Cheese_Heist

@MainActor
struct LevelSelectViewModelTests {

    @Test("starts with initial current stop selected and route matching")
    func startsWithInitialSelection() {
        let viewModel = LevelSelectViewModel()
        #expect(viewModel.selectedStopID == 1)
        #expect(viewModel.selectedRoute == .level2)
        #expect(viewModel.stops[0].kind == .marker(number: 1))
        #expect(viewModel.stops[1].kind == .current)
        #expect(viewModel.stops[2].kind == .locked)
    }

    @Test("tapping an unlocked marker updates it to .current and reverts previous to .marker")
    func selectUnlockedMarkerUpdatesCurrent() {
        let viewModel = LevelSelectViewModel()

        let success = viewModel.selectStop(id: 0)
        #expect(success)
        #expect(viewModel.selectedStopID == 0)
        #expect(viewModel.selectedRoute == .level1)
        #expect(viewModel.stops[0].kind == .current)
        #expect(viewModel.stops[1].kind == .marker(number: 2))
        #expect(viewModel.stops[2].kind == .locked)
    }

    @Test("tapping back and forth toggles .current correctly")
    func toggleBetweenLevels() {
        let viewModel = LevelSelectViewModel()

        viewModel.selectStop(id: 0)
        #expect(viewModel.stops[0].kind == .current)
        #expect(viewModel.stops[1].kind == .marker(number: 2))
        #expect(viewModel.selectedRoute == .level1)

        viewModel.selectStop(id: 1)
        #expect(viewModel.stops[0].kind == .marker(number: 1))
        #expect(viewModel.stops[1].kind == .current)
        #expect(viewModel.selectedRoute == .level2)
    }

    @Test("tapping the already current stop is a no-op")
    func tapCurrentStopIsNoOp() {
        let viewModel = LevelSelectViewModel()
        #expect(viewModel.selectedStopID == 1)

        let success = viewModel.selectStop(id: 1)
        #expect(!success)
        #expect(viewModel.selectedStopID == 1)
        #expect(viewModel.stops[1].kind == .current)
    }

    @Test("tapping a locked stop is ignored and does not change selection")
    func tapLockedStopIsIgnored() {
        let viewModel = LevelSelectViewModel()

        let success = viewModel.selectStop(id: 2)
        #expect(!success)
        #expect(viewModel.selectedStopID == 1)
        #expect(viewModel.selectedRoute == .level2)
        #expect(viewModel.stops[2].kind == .locked)
        #expect(viewModel.stops[1].kind == .current)
    }

    @Test("tapping an invalid stop id returns false")
    func tapInvalidIdReturnsFalse() {
        let viewModel = LevelSelectViewModel()
        let success = viewModel.selectStop(id: 999)
        #expect(!success)
        #expect(viewModel.selectedStopID == 1)
    }
}
