//
//  Item.swift
//  Cheese Heist
//
//  Created by Axel Nino Nakata on 10/08/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
