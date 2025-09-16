//
//  CreateRouteViewModel.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-15.
//

import SwiftUI
import CoreData
import MapKit

@MainActor
class CreateRouteViewModel: ObservableObject {
    @Published var routeName: String = ""
    @Published var routeStops: [RouteStop] = []
    @Published var isCreatingRoute = false
    @Published var routeCreated = false

    private let coreDataManager = CoreDataManager.shared
    
    var canCreateRoute: Bool {
        !routeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        routeStops.count >= 2
    }
    
    func addStop(_ savedPin: SavedPinEntity) {
        let newOrder = (routeStops.map { $0.order }.max() ?? 0) + 1
        let newStop = RouteStop(savedPin: savedPin, order: newOrder)
        routeStops.append(newStop)
    }

    func removeStop(_ stop: RouteStop) {
        routeStops.removeAll { $0.id == stop.id }
        // Reorder remaining stops
        reorderStops()
    }

    
    private func reorderStops() {
        routeStops = routeStops.sorted(by: { $0.order < $1.order })
        for (index, _) in routeStops.enumerated() {
            routeStops[index].order = index + 1
        }
    }
    
    func createRoute() {
        guard canCreateRoute else { return }
        
        isCreatingRoute = true
        
        // Create the route in Core Data
        if let createdRoute = RouteEntity.createRoute(
            name: routeName.trimmingCharacters(in: .whitespacesAndNewlines),
            stops: routeStops,
            context: coreDataManager.context
        ) {
            // Calculate total distance asynchronously
            calculateAndUpdateRouteDistance(for: createdRoute)
            
            // Reset the form
            routeName = ""
            routeStops = []
            routeCreated = true
        }
        
        isCreatingRoute = false
    }
    
    private func calculateAndUpdateRouteDistance(for route: RouteEntity) {
        let orderedStops = route.orderedStops
        guard orderedStops.count >= 2 else { return }
        
        var totalDistance: Double = 0
        let group = DispatchGroup()
        
        for i in 0..<(orderedStops.count - 1) {
            let currentStop = orderedStops[i]
            let nextStop = orderedStops[i + 1]
            
            guard let currentPin = currentStop.savedPin,
                  let nextPin = nextStop.savedPin else { continue }
            
            let sourceCoordinate = CLLocationCoordinate2D(
                latitude: currentPin.latitude,
                longitude: currentPin.longitude
            )
            let destinationCoordinate = CLLocationCoordinate2D(
                latitude: nextPin.latitude,
                longitude: nextPin.longitude
            )
            
            group.enter()
            
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: sourceCoordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                defer { group.leave() }
                
                if let route = response?.routes.first {
                    totalDistance += route.distance
                }
            }
        }
        
        group.notify(queue: .main) {
            route.updateTotalDistance(totalDistance, context: self.coreDataManager.context)
        }
    }
    
    func resetForm() {
        routeName = ""
        routeStops = []
        routeCreated = false
    }

}