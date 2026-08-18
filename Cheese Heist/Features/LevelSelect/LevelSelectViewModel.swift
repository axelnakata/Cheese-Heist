//
//  LevelSelectViewModel.swift
//  Cheese Heist
//
//  Presentation-only. `stops` is the whole of today's state — there is nothing to
//  select yet because only Level 1 is unlocked. A tap target on a locked stop is a
//  future extension point once more levels ship, not something this file predicts.
//

import Observation

@Observable
final class LevelSelectViewModel {

    let stops: [LevelSelectStop] = LevelSelectPath.stops
}
