//
//  SavedPinAnnotation.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-19.
//

import Foundation
import MapKit

// MARK: - SavedPinAnnotation

class SavedPinAnnotation: NSObject, MKAnnotation {
    let savedPin: SavedPinEntity
    
    var coordinate: CLLocationCoordinate2D {
        return savedPin.coordinate
    }
    
    var title: String? {
        return savedPin.placeName
    }
    
    var subtitle: String? {
        return savedPin.shortAddress
    }
    
    init(savedPin: SavedPinEntity) {
        self.savedPin = savedPin
        super.init()
    }
}