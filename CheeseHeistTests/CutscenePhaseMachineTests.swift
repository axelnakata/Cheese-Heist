//
//  CutscenePhaseMachineTests.swift
//  CheeseHeistTests
//
//  Every transition in the cutscene phase machine, plus every rejected event returns nil.
//

import Testing
@testable import Cheese_Heist

struct CutscenePhaseMachineTests {

    let beatCount = CutsceneScript.beats.count

    // MARK: - Happy path

    @Test("scanning + tappedSurface → introducing")
    func scanningToIntroducing() {
        let next = CutscenePhaseMachine.next(from: .scanning, on: .tappedSurface, beatCount: beatCount)
        #expect(next == .introducing)
    }

    @Test("introducing + tappedContinue → narrating(0)")
    func introducingToNarrating() {
        let next = CutscenePhaseMachine.next(from: .introducing, on: .tappedContinue, beatCount: beatCount)
        #expect(next == .narrating(0))
    }

    @Test("narrating(0) + tappedContinue → narrating(1)")
    func narratingAdvances() {
        let next = CutscenePhaseMachine.next(from: .narrating(0), on: .tappedContinue, beatCount: beatCount)
        #expect(next == .narrating(1))
    }

    @Test("last beat + tappedBlueprint → handingOff")
    func lastBeatBlueprintHandoff() {
        let last = beatCount - 1
        let next = CutscenePhaseMachine.next(from: .narrating(last), on: .tappedBlueprint, beatCount: beatCount)
        #expect(next == .handingOff)
    }

    // MARK: - Rejected events

    @Test("scanning + tappedContinue → nil")
    func scanningRejectsContinue() {
        let next = CutscenePhaseMachine.next(from: .scanning, on: .tappedContinue, beatCount: beatCount)
        #expect(next == nil)
    }

    @Test("scanning + tappedBlueprint → nil")
    func scanningRejectsBlueprint() {
        let next = CutscenePhaseMachine.next(from: .scanning, on: .tappedBlueprint, beatCount: beatCount)
        #expect(next == nil)
    }

    @Test("introducing + tappedSurface → nil")
    func introducingRejectsSurface() {
        let next = CutscenePhaseMachine.next(from: .introducing, on: .tappedSurface, beatCount: beatCount)
        #expect(next == nil)
    }

    @Test("last beat + tappedContinue → nil (must tap blueprint)")
    func lastBeatRejectsContinue() {
        let last = beatCount - 1
        let next = CutscenePhaseMachine.next(from: .narrating(last), on: .tappedContinue, beatCount: beatCount)
        #expect(next == nil)
    }

    @Test("non-last beat + tappedBlueprint → nil")
    func nonLastBeatRejectsBlueprint() {
        let next = CutscenePhaseMachine.next(from: .narrating(0), on: .tappedBlueprint, beatCount: beatCount)
        #expect(next == nil)
    }

    @Test("handingOff rejects everything")
    func handingOffRejectsAll() {
        #expect(CutscenePhaseMachine.next(from: .handingOff, on: .tappedSurface, beatCount: beatCount) == nil)
        #expect(CutscenePhaseMachine.next(from: .handingOff, on: .tappedContinue, beatCount: beatCount) == nil)
        #expect(CutscenePhaseMachine.next(from: .handingOff, on: .tappedBlueprint, beatCount: beatCount) == nil)
    }
}
