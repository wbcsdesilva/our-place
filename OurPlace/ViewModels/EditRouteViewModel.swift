//
//  EditRouteViewModel.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-15.
//

import SwiftUI
import CoreData
import MapKit

@MainActor
class EditRouteViewModel: ObservableObject {
    @Published var routeName: String = ""
    @Published var routeStops: [RouteStop] = []
    @Published var isSaving = false
    @Published var changesSaved = false

    private let route: RouteEntity
    private let coreDataManager = CoreDataService.shared

    var canSave: Bool {
        !routeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        routeStops.count >= 2
    }

    init(route: RouteEntity) {
        self.route = route
        loadRouteData()
    }

    private func loadRouteData() {
        routeName = route.name

        // Convert RouteStopEntity to RouteStop for editing
        routeStops = route.orderedStops.map { stopEntity in
            RouteStop(savedPin: stopEntity.savedPin!, order: Int(stopEntity.order))
        }
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

    func saveChanges() {
        guard canSave else { return }

        isSaving = true

        // Update route name
        route.name = routeName.trimmingCharacters(in: .whitespacesAndNewlines)
        route.updatedAt = Date()

        // Delete existing stops
        for existingStop in route.orderedStops {
            coreDataManager.context.delete(existingStop)
        }

        // Create new stops
        for routeStop in routeStops {
            let stopEntity = RouteStopEntity(context: coreDataManager.context,
                                           savedPin: routeStop.savedPin,
                                           order: Int16(routeStop.order))
            stopEntity.route = route
        }

        do {
            try coreDataManager.context.save()

            // Calculate and update total distance asynchronously
            calculateAndUpdateRouteDistance()

            changesSaved = true
        } catch {
            print("Failed to save route changes: \(error)")
        }

        isSaving = false
    }

    private func calculateAndUpdateRouteDistance() {
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
            self.route.updateTotalDistance(totalDistance, context: self.coreDataManager.context)
        }
    }

}