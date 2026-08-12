//
//  GearPairVoteTests.swift
//  CheeseHeistTests
//
//  PRD §12.1 — convergence and rejection.
//
//  A lock should mean "two gears, steadily", not "two gears, eventually", so the
//  interesting cases here are the ones where a disagreeing frame arrives.
//

import Testing
@testable import Cheese_Heist

struct GearPairVoteTests {

    @Test("three agreeing frames settle the pair")
    func convergesAfterThree() {
        var vote = GearPairVote()

        #expect(vote.submit((.eightTooth, .fortyTooth)) == nil)
        #expect(vote.submit((.eightTooth, .fortyTooth)) == nil)

        let settled = vote.submit((.eightTooth, .fortyTooth))
        #expect(settled?.0 == .eightTooth)
        #expect(settled?.1 == .fortyTooth)
    }

    /// Order in the frame is not order in the vote — the same two gears seen from the
    /// other side must not restart the streak.
    @Test("the pair is order-independent")
    func orderDoesNotMatter() {
        var vote = GearPairVote()
        vote.submit((.eightTooth, .fortyTooth))
        vote.submit((.fortyTooth, .eightTooth))

        #expect(vote.submit((.eightTooth, .fortyTooth)) != nil)
    }

    @Test("a disagreeing frame clears the streak")
    func disagreementResets() {
        var vote = GearPairVote()
        vote.submit((.eightTooth, .fortyTooth))
        vote.submit((.eightTooth, .fortyTooth))

        // One misclassification, and the count starts again.
        #expect(vote.submit((.eightTooth, .twentyFourTooth)) == nil)
        #expect(vote.submit((.eightTooth, .twentyFourTooth)) == nil)
        #expect(vote.submit((.eightTooth, .twentyFourTooth)) != nil)
    }

    /// A frame that did not show exactly two gears breaks the streak from outside.
    @Test("reset clears an in-flight vote")
    func resetClears() {
        var vote = GearPairVote()
        vote.submit((.eightTooth, .fortyTooth))
        vote.submit((.eightTooth, .fortyTooth))
        vote.reset()

        #expect(vote.streak == 0)
        #expect(vote.consensus == nil)
        #expect(vote.submit((.eightTooth, .fortyTooth)) == nil)
    }

    @Test("progress tracks the slower of the two things a lock waits on")
    func progressIsMonotonic() {
        var vote = GearPairVote()
        #expect(vote.progress == 0)

        vote.submit((.twentyFourTooth, .fortyTooth))
        #expect(abs(vote.progress - 1.0 / 3) < 1e-12)

        vote.submit((.twentyFourTooth, .fortyTooth))
        vote.submit((.twentyFourTooth, .fortyTooth))
        #expect(vote.progress == 1)
    }

    @Test("a settled pair is reported smaller gear first")
    func consensusIsOrdered() {
        var vote = GearPairVote()
        for _ in 0..<3 { vote.submit((.fortyTooth, .twentyFourTooth)) }

        #expect(vote.consensus?.0 == .twentyFourTooth)
        #expect(vote.consensus?.1 == .fortyTooth)
    }
}
