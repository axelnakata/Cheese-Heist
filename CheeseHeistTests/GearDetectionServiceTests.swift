//
//  GearDetectionServiceTests.swift
//  CheeseHeistTests
//
//  Tests for live detection signals: wrong gear count debounce during setup and
//  tracking lost (crane lost) mid-game.
//

import Foundation
import Testing
@testable import Cheese_Heist

@MainActor
struct GearDetectionServiceTests {

    static let debounce = GearDetectionService.gearCountIssueDebounceAfter
    static let trackingLost = GearDetectionService.trackingLostAfter

    @Test("liveGearCountIssue enters .tooFew after debounce duration")
    func wrongGearCountDebouncesTooFew() {
        let service = GearDetectionService()

        #expect(service.liveGearCountIssue == nil)

        // First frame with 1 gear at t = 100.0
        service.noteWrongGearCount(count: 1, now: 100.0)
        #expect(service.liveGearCountIssue == nil)

        // Still under the debounce window
        service.noteWrongGearCount(count: 1, now: 100.0 + Self.debounce / 2)
        #expect(service.liveGearCountIssue == nil)

        // Debounce expires
        service.noteWrongGearCount(count: 1, now: 100.0 + Self.debounce)
        #expect(service.liveGearCountIssue == .tooFew)
    }

    @Test("liveGearCountIssue enters .tooMany after debounce duration")
    func wrongGearCountDebouncesTooMany() {
        let service = GearDetectionService()

        service.noteWrongGearCount(count: 3, now: 200.0)
        #expect(service.liveGearCountIssue == nil)

        service.noteWrongGearCount(count: 3, now: 200.0 + Self.debounce)
        #expect(service.liveGearCountIssue == .tooMany(3))
    }

    @Test("a valid 2-gear frame clears wrong gear count immediately")
    func validFrameClearsWrongGearCount() {
        let service = GearDetectionService()

        service.noteWrongGearCount(count: 1, now: 300.0)
        service.noteWrongGearCount(count: 1, now: 300.0 + Self.debounce + 0.1)
        #expect(service.liveGearCountIssue == .tooFew)

        service.clearWrongGearCount()
        #expect(service.liveGearCountIssue == nil)
        #expect(service.wrongCountCandidate == nil)
    }

    @Test("recheckGearCountIssue clears live issue and rearms debounce")
    func recheckRearmsDebounce() {
        let service = GearDetectionService()

        service.noteWrongGearCount(count: 1, now: 400.0)
        service.noteWrongGearCount(count: 1, now: 400.0 + Self.debounce)
        #expect(service.liveGearCountIssue == .tooFew)

        // User taps "I fixed it!"
        service.recheckGearCountIssue()
        #expect(service.liveGearCountIssue == nil)

        // New tick with 1 gear still wrong starts a fresh debounce window
        let rearmedAt = 400.0 + Self.debounce + 0.1
        service.noteWrongGearCount(count: 1, now: rearmedAt)
        #expect(service.liveGearCountIssue == nil)

        // Debounce expires
        service.noteWrongGearCount(count: 1, now: rearmedAt + Self.debounce)
        #expect(service.liveGearCountIssue == .tooFew)
    }

    @Test("tracking lost flags hasLostGears after threshold")
    func trackingLostFlagsAfterThreshold() {
        let service = GearDetectionService()
        service.lastTrackedAt = 500.0

        #expect(!service.hasLostGears)

        // Under the threshold
        service.noteTrackingGap(now: 500.0 + Self.trackingLost - 0.5)
        #expect(!service.hasLostGears)

        // Exceeds the threshold
        service.noteTrackingGap(now: 500.0 + Self.trackingLost + 0.1)
        #expect(service.hasLostGears)
    }

    @Test("stop and reset clear all live issue and tracking gap states")
    func stopAndResetClearStates() {
        let service = GearDetectionService()
        service.noteWrongGearCount(count: 1, now: 600.0)
        service.noteWrongGearCount(count: 1, now: 600.0 + Self.debounce)
        service.lastTrackedAt = 600.0
        service.noteTrackingGap(now: 600.0 + Self.trackingLost + 0.1)

        #expect(service.liveGearCountIssue == .tooFew)
        #expect(service.hasLostGears)

        service.stop()
        #expect(service.liveGearCountIssue == nil)
        #expect(!service.hasLostGears)
    }
}
