//
//  DialogueSequencer.swift
//  Cheese Heist
//
//  Owns the beat index and the reveal gate for a run of speech bubbles.
//
//  THE VIEWMODEL NEVER COUNTS BEATS. `introDialogue` is two lines and every other
//  teaching phase is one; without this the phase machine would need a case per line and
//  the "which line am I on" state would live next to the phase, where a stray reset
//  would silently skip a lesson.
//
//  A tap during the typewriter reveal completes the line rather than advancing past it.
//  Children tap constantly, and losing a sentence to an eager tap is the single easiest
//  way to lose the lesson.
//

import Foundation
import Observation

@MainActor
@Observable
final class DialogueSequencer {

    private(set) var beats: [DialogueBeat] = []
    private(set) var index = 0

    /// False while the typewriter is still revealing the current beat.
    private(set) var isRevealComplete = false

    var current: DialogueBeat? {
        beats.indices.contains(index) ? beats[index] : nil
    }

    var isFinished: Bool { index >= beats.count }

    /// Starts a new run of beats.
    func present(_ beats: [DialogueBeat]) {
        self.beats = beats
        index = 0
        isRevealComplete = beats.isEmpty
    }

    /// The typewriter finished revealing the current beat.
    func markRevealComplete() {
        isRevealComplete = true
    }

    /// A tap. Returns true when the run has finished and the caller should advance the
    /// phase; false when the tap was consumed by completing or advancing a beat.
    func advance() -> Bool {
        guard isRevealComplete else {
            // Skip the reveal, do not skip the line.
            isRevealComplete = true
            return false
        }

        index += 1
        isRevealComplete = false
        return isFinished
    }

    func reset() {
        beats = []
        index = 0
        isRevealComplete = false
    }
}
