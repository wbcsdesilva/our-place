//
//  RouteNavigationViewModel.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-16.
//

import Foundation
import MapKit
import CoreLocation

@MainActor
class RouteNavigationViewModel: NSObject, ObservableObject {
    @Published var route: RouteEntity
    @Published var routeStops: [RouteStopEntity] = []
    @Published var currentStopIndex: Int = 0
    @Published var userLocation: CLLocationCoordinate2D?

    // Current navigation state
    @Published var currentRoute: MKRoute?
    @Published var isCalculatingRoute = false
    @Published var routeError: String?
    @Published var transportType: MKDirectionsTransportType = .automobile

    // Full route visualization
    @Published var allRouteSegments: [MKRoute] = []
    @Published var currentSegmentIndex: Int = 0
    @Published var isCalculatingFullRoute = false

    // Route progress
    @Published var currentRouteDistance: CLLocationDistance = 0
    @Published var currentRouteETA: TimeInterval = 0
    @Published var totalRemainingDistance: CLLocationDistance = 0
    @Published var totalRouteDistance: CLLocationDistance = 0
    @Published var totalRouteETA: TimeInterval = 0

    // Auto-advance settings
    private let proximityThreshold: CLLocationDistance = 50 // 50 meters
    private let locationManager = CLLocationManager()

    init(route: RouteEntity) {
        self.route = route
        super.init()
        setupLocationManager()
        loadRouteStops()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    private func loadRouteStops() {
        routeStops = route.orderedStops
    }

    func startNavigation() {
        guard !routeStops.isEmpty else { return }
        currentStopIndex = 0
        currentSegmentIndex = 0
        calculateFullRoute()
    }

    private func proceedToNextStop() {
        guard currentStopIndex < routeStops.count - 1 else { return }
        currentStopIndex += 1
        currentSegmentIndex += 1
        updateCurrentRoute()
        calculateTotalRemainingDistance()
    }

    private func calculateRouteToCurrentStop() {
        guard let userLocation = userLocation,
              currentStopIndex < routeStops.count,
              let currentStop = routeStops[currentStopIndex].savedPin else {
            return
        }

        let destination = CLLocationCoordinate2D(
            latitude: currentStop.latitude,
            longitude: currentStop.longitude
        )

        calculateRoute(from: userLocation, to: destination)
    }

    private func calculateFullRoute() {
        guard let userLocation = userLocation, !routeStops.isEmpty else { return }

        isCalculatingFullRoute = true
        routeError = nil
        allRouteSegments = []

        var routeRequests: [(source: CLLocationCoordinate2D, destination: CLLocationCoordinate2D)] = []

        // First segment: user location to first stop
        if let firstStop = routeStops.first?.savedPin {
            let firstDestination = CLLocationCoordinate2D(
                latitude: firstStop.latitude,
                longitude: firstStop.longitude
            )
            routeRequests.append((source: userLocation, destination: firstDestination))
        }

        // Segments between consecutive stops
        for i in 0..<(routeStops.count - 1) {
            guard let currentStop = routeStops[i].savedPin,
                  let nextStop = routeStops[i + 1].savedPin else { continue }

            let source = CLLocationCoordinate2D(
                latitude: currentStop.latitude,
                longitude: currentStop.longitude
            )
            let destination = CLLocationCoordinate2D(
                latitude: nextStop.latitude,
                longitude: nextStop.longitude
            )
            routeRequests.append((source: source, destination: destination))
        }

        calculateMultipleRoutes(requests: routeRequests)
    }

    private func calculateMultipleRoutes(requests: [(source: CLLocationCoordinate2D, destination: CLLocationCoordinate2D)]) {
        let group = DispatchGroup()
        var calculatedRoutes: [Int: MKRoute] = [:]
        var hasError = false

        for (index, request) in requests.enumerated() {
            group.enter()

            let mkRequest = MKDirections.Request()
            mkRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: request.source))
            mkRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: request.destination))
            mkRequest.transportType = transportType

            let directions = MKDirections(request: mkRequest)

            directions.calculate { response, error in
                defer { group.leave() }

                if let route = response?.routes.first {
                    calculatedRoutes[index] = route
                } else {
                    hasError = true
                }
            }
        }

        group.notify(queue: .main) {
            if hasError {
                self.routeError = "Failed to calculate complete route"
                self.isCalculatingFullRoute = false
                return
            }

            // Sort routes by index and store them
            self.allRouteSegments = (0..<requests.count).compactMap { calculatedRoutes[$0] }
            self.updateCurrentRoute()
            self.calculateTotalRouteStats()
            self.isCalculatingFullRoute = false
        }
    }

    private func updateCurrentRoute() {
        guard currentSegmentIndex < allRouteSegments.count else { return }

        currentRoute = allRouteSegments[currentSegmentIndex]
        if let route = currentRoute {
            currentRouteDistance = route.distance
            currentRouteETA = route.expectedTravelTime
        }
    }

    private func calculateTotalRouteStats() {
        totalRouteDistance = allRouteSegments.reduce(0) { $0 + $1.distance }
        totalRouteETA = allRouteSegments.reduce(0) { $0 + $1.expectedTravelTime }
        calculateTotalRemainingDistance()
    }

    private func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
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
                        self.currentRouteDistance = route.distance
                        self.currentRouteETA = route.expectedTravelTime
                        self.calculateTotalRemainingDistance()
                    } else {
                        self.routeError = "No routes available"
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

    private func calculateTotalRemainingDistance() {
        // Calculate remaining distance from current segment onwards
        totalRemainingDistance = 0

        for i in currentSegmentIndex..<allRouteSegments.count {
            totalRemainingDistance += allRouteSegments[i].distance
        }
    }

    func changeTransportType(_ type: MKDirectionsTransportType) {
        guard transportType != type else { return }
        transportType = type
        calculateFullRoute()
    }

    private func checkProximityToCurrentStop(userLocation: CLLocation) {
        guard let currentDestination = currentDestination,
              !isLastStop else { return }

        let destinationLocation = CLLocation(
            latitude: currentDestination.latitude,
            longitude: currentDestination.longitude
        )

        let distanceToDestination = userLocation.distance(from: destinationLocation)

        // Auto-advance when within proximity threshold
        if distanceToDestination <= proximityThreshold {
            print("🎯 Auto-advancing: Within \(Int(distanceToDestination))m of \(currentDestination.placeName)")
            proceedToNextStop()
        }
    }

    // MARK: - Computed Properties

    var currentDestination: SavedPinEntity? {
        guard currentStopIndex < routeStops.count else { return nil }
        return routeStops[currentStopIndex].savedPin
    }

    var isLastStop: Bool {
        return currentStopIndex >= routeStops.count - 1
    }

    var progressText: String {
        return "Stop \(currentStopIndex + 1) of \(routeStops.count)"
    }

    var formattedCurrentDistance: String {
        let formatter = MKDistanceFormatter()
        return formatter.string(fromDistance: currentRouteDistance)
    }

    var formattedCurrentETA: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        let formattedString = formatter.string(from: currentRouteETA) ?? ""
        return formattedString.replacingOccurrences(of: " m", with: " min").replacingOccurrences(of: "m", with: "min")
    }

    var formattedTotalDistance: String {
        let formatter = MKDistanceFormatter()
        return formatter.string(fromDistance: totalRemainingDistance)
    }

    var formattedTotalRouteDistance: String {
        let formatter = MKDistanceFormatter()
        return formatter.string(fromDistance: totalRouteDistance)
    }

    var formattedTotalRouteETA: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        let formattedString = formatter.string(from: totalRouteETA) ?? ""
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
}

// MARK: - CLLocationManagerDelegate

extension RouteNavigationViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            userLocation = location.coordinate

            // Calculate full route if we don't have one yet
            if allRouteSegments.isEmpty && !routeStops.isEmpty {
                calculateFullRoute()
            }

            // Check for auto-advance to next stop
            checkProximityToCurrentStop(userLocation: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("Location error: \(error)")
            routeError = "Location unavailable"
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                locationManager.startUpdatingLocation()
            case .denied, .restricted:
                routeError = "Location access denied"
            default:
                break
            }
        }
    }
}
