//
//  RouteDetailsViewModel.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-15.
//

import SwiftUI
import CoreLocation
import MapKit

class RouteDetailsViewModel: NSObject, ObservableObject {
    @Published var currentStops: [RouteStopEntity] = []
    @Published var totalDistance: String = "0.0km"
    @Published var distanceFromUserLocation: String = "Unknown"
    @Published var userLocation: CLLocation?

    private let route: RouteEntity
    private let locationManager = CLLocationManager()

    init(route: RouteEntity) {
        self.route = route
        super.init()
        setupLocationManager()
        loadRouteStops()
        updateDistanceFromUser()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    private func loadRouteStops() {
        currentStops = route.orderedStops
        totalDistance = route.formattedDistance
    }

    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }

    private func updateDistanceFromUser() {
        guard let userLocation = userLocation,
              let firstStop = currentStops.first,
              let firstPin = firstStop.savedPin else {
            distanceFromUserLocation = "Location unavailable"
            return
        }

        let firstStopLocation = CLLocation(
            latitude: firstPin.latitude,
            longitude: firstPin.longitude
        )

        let distanceToFirstStop = userLocation.distance(from: firstStopLocation)
        let distanceInKm = distanceToFirstStop / 1000.0
        distanceFromUserLocation = String(format: "%.1fkm to first stop", distanceInKm)
    }

    func refreshRouteData() {
        loadRouteStops()
        updateDistanceFromUser()
    }
}

// MARK: - CLLocationManagerDelegate

extension RouteDetailsViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            userLocation = location
            updateDistanceFromUser()

            // Stop updating location to save battery
            locationManager.stopUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("Failed to get user location: \(error)")
            distanceFromUserLocation = "Location unavailable"
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                locationManager.startUpdatingLocation()
            case .denied, .restricted:
                distanceFromUserLocation = "Location access denied"
            default:
                break
            }
        }
    }
}