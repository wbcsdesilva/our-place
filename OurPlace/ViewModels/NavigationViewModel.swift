//
//  NavigationViewModel.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-21.
//

import Foundation
import MapKit
import CoreLocation

@MainActor
class NavigationViewModel: ObservableObject {
    @Published var isNavigating = false
    @Published var currentRoute: MKRoute?
    @Published var routeDistance: CLLocationDistance = 0
    @Published var routeETA: TimeInterval = 0
    @Published var transportType: MKDirectionsTransportType = .automobile
    @Published var isCalculatingRoute = false
    @Published var routeError: String?
    
    private let locationManager = CLLocationManager()
    
    @Published var destinationPin: SavedPinEntity?
    @Published var destinationCoordinate: CLLocationCoordinate2D?
    
    func startNavigation(to pin: SavedPinEntity, from userLocation: CLLocationCoordinate2D) {
        destinationPin = pin
        destinationCoordinate = pin.coordinate
        calculateRoute(from: userLocation, to: pin.coordinate)
    }
    
    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        isCalculatingRoute = true
        routeError = nil
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = transportType
        
        let directions = MKDirections(request: request)
        
        Task {
            do {
                let response = try await directions.calculate()
                
                await MainActor.run {
                    if let route = response.routes.first {
                        self.currentRoute = route
                        self.routeDistance = route.distance
                        self.routeETA = route.expectedTravelTime
                        self.isNavigating = true
                    } else {
                        self.routeError = "No routes available for \(self.transportType.rawValue) mode"
                    }
                    self.isCalculatingRoute = false
                }
            } catch {
                await MainActor.run {
                    self.routeError = "Failed to calculate route: \(error.localizedDescription)"
                    self.isCalculatingRoute = false
                }
            }
        }
    }
    
    func changeTransportType(_ type: MKDirectionsTransportType, userLocation: CLLocationCoordinate2D) {
        guard let destination = destinationCoordinate else { return }
        guard transportType != type else { return }
        
        transportType = type
        calculateRoute(from: userLocation, to: destination)
    }
    
    func cancelNavigation() {
        isNavigating = false
        isCalculatingRoute = false
        currentRoute = nil
        destinationPin = nil
        destinationCoordinate = nil
        routeDistance = 0
        routeETA = 0
        routeError = nil
    }
    
    var formattedDistance: String {
        let formatter = MKDistanceFormatter()
        return formatter.string(fromDistance: routeDistance)
    }
    
    var formattedETA: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        let formattedString = formatter.string(from: routeETA) ?? ""
        return formattedString.replacingOccurrences(of: " m", with: " min").replacingOccurrences(of: "m", with: "min")
    }
    
    var transportIcon: String {
        switch transportType {
        case .automobile:
            return "car.fill"
        case .walking:
            return "figure.walk"
        default:
            return "car.fill"
        }
    }
    
    var transportTypeName: String {
        return transportTypeNameFor(transportType)
    }
    
    private func transportTypeNameFor(_ type: MKDirectionsTransportType) -> String {
        switch type {
        case .automobile:
            return "Driving"
        case .walking:
            return "Walking"
        default:
            return "Unknown"
        }
    }
}