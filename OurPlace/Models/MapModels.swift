//
//  MapModels.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-18.
//

import Foundation
import CoreLocation

// MARK: - Map Data Models

struct DroppedPin: Identifiable {
    let id: UUID
    var coordinate: CLLocationCoordinate2D
    let timestamp: Date
}

struct NearbyPlace: Identifiable {
    let id: UUID
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Extensions

