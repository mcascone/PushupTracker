//
//  Item.swift
//  PushupTracker
//
//  Created by Maximilian Cascone on 4/23/26.
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
