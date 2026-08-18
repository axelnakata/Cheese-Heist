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

    @Test("liveGearCountIssue enters .tooFew after debounce duration")
    func wrongGearCountDebouncesTooFew() {
        let service = GearDetectionService()

        #expect(service.liveGearCountIssue == nil)

        // First frame with 1 gear at t = 100.0
        service.noteWrongGearCount(count: 1, now: 100.0)
        #expect(service.liveGearCountIssue == nil)

        // Half a second later (t = 100.5) — still under 1.0s debounce
        service.noteWrongGearCount(count: 1, now: 100.5)
        #expect(service.liveGearCountIssue == nil)

        // Debounce expires at t = 101.0
        service.noteWrongGearCount(count: 1, now: 101.0)
        #expect(service.liveGearCountIssue == .tooFew)
    }

    @Test("liveGearCountIssue enters .tooMany after debounce duration")
    func wrongGearCountDebouncesTooMany() {
        let service = GearDetectionService()

        service.noteWrongGearCount(count: 3, now: 200.0)
        #expect(service.liveGearCountIssue == nil)

        service.noteWrongGearCount(count: 3, now: 201.0)
        #expect(service.liveGearCountIssue == .tooMany(3))
    }

    @Test("a valid 2-gear frame clears wrong gear count immediately")
    func validFrameClearsWrongGearCount() {
        let service = GearDetectionService()

        service.noteWrongGearCount(count: 1, now: 300.0)
        service.noteWrongGearCount(count: 1, now: 301.1)
        #expect(service.liveGearCountIssue == .tooFew)

        service.clearWrongGearCount()
        #expect(service.liveGearCountIssue == nil)
        #expect(service.wrongCountCandidate == nil)
    }

    @Test("recheckGearCountIssue clears live issue and rearms debounce")
    func recheckRearmsDebounce() {
        let service = GearDetectionService()

        service.noteWrongGearCount(count: 1, now: 400.0)
        service.noteWrongGearCount(count: 1, now: 401.0)
        #expect(service.liveGearCountIssue == .tooFew)

        // User taps "I fixed it!"
        service.recheckGearCountIssue()
        #expect(service.liveGearCountIssue == nil)

        // New tick with 1 gear still wrong at t = 401.1 starts fresh debounce window
        service.noteWrongGearCount(count: 1, now: 401.1)
        #expect(service.liveGearCountIssue == nil)

        // Debounce expires at t = 402.1
        service.noteWrongGearCount(count: 1, now: 402.1)
        #expect(service.liveGearCountIssue == .tooFew)
    }

    @Test("tracking lost flags hasLostGears after threshold")
    func trackingLostFlagsAfterThreshold() {
        let service = GearDetectionService()
        service.lastTrackedAt = 500.0

        #expect(!service.hasLostGears)

        // 1.0s later — below 1.5s threshold
        service.noteTrackingGap(now: 501.0)
        #expect(!service.hasLostGears)

        // 1.6s later — exceeds 1.5s threshold
        service.noteTrackingGap(now: 501.6)
        #expect(service.hasLostGears)
    }

    @Test("stop and reset clear all live issue and tracking gap states")
    func stopAndResetClearStates() {
        let service = GearDetectionService()
        service.noteWrongGearCount(count: 1, now: 600.0)
        service.noteWrongGearCount(count: 1, now: 601.0)
        service.lastTrackedAt = 600.0
        service.noteTrackingGap(now: 602.0)

        #expect(service.liveGearCountIssue == .tooFew)
        #expect(service.hasLostGears)

        service.stop()
        #expect(service.liveGearCountIssue == nil)
        #expect(!service.hasLostGears)
    }
}
