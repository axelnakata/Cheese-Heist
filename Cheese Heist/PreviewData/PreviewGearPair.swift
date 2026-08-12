//
//  PreviewGearPair.swift
//  Cheese Heist
//
//  Gear pairs for previews and mocks.
//

enum PreviewGearPair {

    /// The Level 1 teaching default: the small gear drives, so the guided run the child
    /// watches first is the SLOW one.
    static let smallAndLarge = GearPair(driver: .eightTooth, follower: .fortyTooth)

    /// The same two gears the other way round — the fast choice.
    static let largeAndSmall = GearPair(driver: .fortyTooth, follower: .eightTooth)

    static let middling = GearPair(driver: .twentyFourTooth, follower: .fortyTooth)
}
