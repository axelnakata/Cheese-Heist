//
//  GearSelectionViewModel.swift
//  Cheese Heist
//
//  Role assignment and the PULL lock.
//
//  D-2: PULL COMMITS, THE JOYSTICK CRANKS. While PULL is on screen the child may keep
//  re-tapping the gears to swap roles as often as they like — the point of the free run
//  is that the choice is theirs, and a choice you cannot change is not one. Tapping
//  PULL locks it in, and PULL is replaced in the same corner by the joystick.
//

import Foundation
import Observation

@MainActor
@Observable
final class GearSelectionViewModel {

    private(set) var assignment: GearRoleAssignment?

    /// True once PULL has been tapped. Tapping a gear after this does nothing.
    private(set) var isLocked = false

    /// Seeds the pair. The initial driver is the caller's choice — Level 1's teaching
    /// run starts on the SMALL gear, which is a `Level1SceneDirector` decision, not one
    /// this type is entitled to make.
    func begin(assignment: GearRoleAssignment) {
        self.assignment = assignment
        isLocked = false
    }

    /// Makes `id` the driver and the other gear the follower. Returns the new
    /// assignment when something actually changed, so the caller can animate.
    @discardableResult
    func assignDriver(_ id: UUID) -> GearRoleAssignment? {
        guard !isLocked, let current = assignment,
              let next = current.assigningDriver(id), next != current else { return nil }

        assignment = next
        return next
    }

    /// PULL. Locks the assignment and hands over to the crank.
    @discardableResult
    func commit() -> GearRoleAssignment? {
        guard !isLocked, let assignment else { return nil }
        isLocked = true
        return assignment
    }

    func reset() {
        assignment = nil
        isLocked = false
    }
}
