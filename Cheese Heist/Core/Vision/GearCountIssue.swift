//
//  GearCountIssue.swift
//  Cheese Heist
//
//  Represents a live tooth/gear count mismatch detected during pre-lock setup.
//

import Foundation

enum GearCountIssue: Equatable, Sendable {
    case tooFew
    case tooMany(Int)
}
