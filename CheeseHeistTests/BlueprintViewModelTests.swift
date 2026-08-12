//
//  BlueprintViewModelTests.swift
//  CheeseHeistTests
//
//  Step navigation: back/next across the 3 steps, and the last step's Next reporting
//  "finished" rather than advancing past the end.
//

import Testing
@testable import Cheese_Heist

@MainActor
struct BlueprintViewModelTests {

    @Test("starts on the first step")
    func startsOnFirstStep() {
        let viewModel = BlueprintViewModel()
        #expect(viewModel.stepIndex == 0)
        #expect(viewModel.isFirstStep)
    }

    @Test("goNext advances through the middle steps and returns false")
    func goNextAdvances() {
        let viewModel = BlueprintViewModel()

        #expect(viewModel.goNext() == false)
        #expect(viewModel.stepIndex == 1)

        #expect(viewModel.goNext() == false)
        #expect(viewModel.stepIndex == 2)
    }

    @Test("goNext on the last step returns true and does not advance further")
    func goNextOnLastStepFinishes() {
        let viewModel = BlueprintViewModel()
        _ = viewModel.goNext()
        _ = viewModel.goNext()
        #expect(viewModel.stepIndex == viewModel.steps.count - 1)

        #expect(viewModel.goNext() == true)
        #expect(viewModel.stepIndex == viewModel.steps.count - 1)
    }

    @Test("goBack retreats and is a no-op on the first step")
    func goBackRetreatsAndClampsAtStart() {
        let viewModel = BlueprintViewModel()
        viewModel.goBack()
        #expect(viewModel.stepIndex == 0)

        _ = viewModel.goNext()
        _ = viewModel.goNext()
        viewModel.goBack()
        #expect(viewModel.stepIndex == 1)
    }

    @Test("isFirstStep is true only on step 0")
    func isFirstStepOnlyOnStepZero() {
        let viewModel = BlueprintViewModel()
        #expect(viewModel.isFirstStep)
        _ = viewModel.goNext()
        #expect(!viewModel.isFirstStep)
    }
}
