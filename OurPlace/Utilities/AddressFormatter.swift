//
//  AddressFormatter.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-18.
//

import Foundation
import CoreLocation
import MapKit

// MARK: - Address Formatting Utilities

func formatAddress(from placemark: CLPlacemark) -> String {
    var addressComponents: [String] = []
    
    if let subThoroughfare = placemark.subThoroughfare {
        addressComponents.append(subThoroughfare)
    }
    
    if let thoroughfare = placemark.thoroughfare {
        addressComponents.append(thoroughfare)
    }
    
    if let locality = placemark.locality {
        addressComponents.append(locality)
    }
    
    return addressComponents.isEmpty ? 
        "\(placemark.location?.coordinate.latitude ?? 0), \(placemark.location?.coordinate.longitude ?? 0)" :
        addressComponents.joined(separator: ", ")
}

func formatAddress(from mapItem: MKPlacemark) -> String {
    var addressComponents: [String] = []
    
    if let subThoroughfare = mapItem.subThoroughfare {
        addressComponents.append(subThoroughfare)
    }
    
    if let thoroughfare = mapItem.thoroughfare {
        addressComponents.append(thoroughfare)
    }
    
    if let locality = mapItem.locality {
        addressComponents.append(locality)
    }
    
    return addressComponents.isEmpty ? 
        "\(mapItem.coordinate.latitude), \(mapItem.coordinate.longitude)" :
        addressComponents.joined(separator: ", ")
}