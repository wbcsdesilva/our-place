//
//  RouteStopModels.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-15.
//

import Foundation

// Model for route creation and editing workflow
struct RouteStop: Identifiable, Equatable {
    let id = UUID()
    let savedPin: SavedPinEntity
    var order: Int
    
    init(savedPin: SavedPinEntity, order: Int) {
        self.savedPin = savedPin
        self.order = order
    }
    
    static func == (lhs: RouteStop, rhs: RouteStop) -> Bool {
        lhs.id == rhs.id
    }
}