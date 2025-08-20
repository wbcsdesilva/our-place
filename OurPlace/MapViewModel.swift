//
//  MapViewModel.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-18.
//

import SwiftUI
import MapKit
import CoreLocation
import CoreData

// MARK: - Map View Model

class MapViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchText = ""
    @Published var cameraPosition = MapCameraPosition.region(
        // TODO: Starting map region and camera position. This is currently set to California, change it to somehwere in Sri Lanka
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.4419, longitude: -122.1419),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    
    @Published var droppedPin: DroppedPin?
    @Published var showPinDetails = false
    @Published var showSavePinView = false
    @Published var reverseGeocodedAddress = ""
    @Published var selectedPlaceName = ""
    @Published var nearbyPlaces: [NearbyPlace] = []
    @Published var isLoadingNearbyPlaces = false
    @Published var savedPinAnnotations: [SavedPinAnnotation] = []
    
    // MARK: - Private Properties
    @Published var currentMapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.4419, longitude: -122.1419),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    private let locationManager = LocationManager()
    private let coreDataManager = CoreDataManager.shared
    
    // MARK: - Computed Properties
    var userLocation: CLLocationCoordinate2D? {
        locationManager.userLocation
    }
    
    // MARK: - Initialization
    init() {
        requestLocationPermission()
        loadSavedPins()
    }
    
    // MARK: - Public Methods
    func requestLocationPermission() {
        locationManager.requestPermission()
    }
    
    func centerOnUserLocation() {
        if let userLocation = locationManager.userLocation {
            withAnimation(.easeInOut(duration: 1.0)) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
    }
    
    func updateCurrentMapRegion(_ region: MKCoordinateRegion) {
        currentMapRegion = region
    }
    
    func dropPinAtCoordinate(_ coordinate: CLLocationCoordinate2D) {
        let pin = DroppedPin(
            id: UUID(),
            coordinate: coordinate,
            timestamp: Date()
        )
        
        droppedPin = pin
        
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: currentMapRegion.span
            ))
        }
        
        reverseGeocode(coordinate: coordinate)
        searchNearbyPlaces(coordinate: coordinate)
        showPinDetails = true
    }
    
    func snapPinToPlace(_ place: NearbyPlace) {
        droppedPin?.coordinate = place.coordinate
        selectedPlaceName = place.name
        // Extract actual address from place.address (remove distance text)
        if let addressPart = place.address.components(separatedBy: " • ").first {
            reverseGeocodedAddress = addressPart
        } else {
            reverseGeocodedAddress = place.address
        }
        showPinDetails = false
        showSavePinView = true
    }
    
    func savePinAsIs() {
        showPinDetails = false
        showSavePinView = true
    }
    
    func getPinPlaceName() -> String {
        if !selectedPlaceName.isEmpty {
            return selectedPlaceName
        } else if !reverseGeocodedAddress.isEmpty {
            return reverseGeocodedAddress
        } else {
            return "Unknown Location"
        }
    }
    
    func dismissPinDetails() {
        showPinDetails = false
        droppedPin = nil
        nearbyPlaces = []
        reverseGeocodedAddress = ""
        selectedPlaceName = ""
    }
    
    // MARK: - Saved Pins Management
    
    func loadSavedPins() {
        let savedPins = SavedPinEntity.fetchAllSavedPins(context: coreDataManager.context)
        savedPinAnnotations = savedPins.map { SavedPinAnnotation(savedPin: $0) }
    }
    
    func loadSavedPinsInRegion(_ region: MKCoordinateRegion) -> [SavedPinAnnotation] {
        // Performance optimization: only show pins in current view region
        return savedPinAnnotations.filter { annotation in
            let latDelta = region.span.latitudeDelta
            let lonDelta = region.span.longitudeDelta
            
            return annotation.coordinate.latitude >= region.center.latitude - latDelta/2 &&
                   annotation.coordinate.latitude <= region.center.latitude + latDelta/2 &&
                   annotation.coordinate.longitude >= region.center.longitude - lonDelta/2 &&
                   annotation.coordinate.longitude <= region.center.longitude + lonDelta/2
        }
    }
    
    func refreshSavedPins() {
        loadSavedPins()
    }
    
    func centerOnSavedPin(_ annotation: SavedPinAnnotation) {
        withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: annotation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
    
    // MARK: - Private Methods
    private func updateRegion(to location: CLLocationCoordinate2D) {
        let newRegion = MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        cameraPosition = .region(newRegion)
        currentMapRegion = newRegion
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    self?.reverseGeocodedAddress = formatAddress(from: placemark)
                } else {
                    self?.reverseGeocodedAddress = "\(coordinate.latitude), \(coordinate.longitude)"
                }
            }
        }
    }
    
    private func searchNearbyPlaces(coordinate: CLLocationCoordinate2D) {
        isLoadingNearbyPlaces = true
        nearbyPlaces = []
        
        let request = MKLocalPointsOfInterestRequest(
            center: coordinate,
            radius: 500 // 500 meters radius
        )
        request.pointOfInterestFilter = .includingAll
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isLoadingNearbyPlaces = false
                
                if error != nil {
                    self?.nearbyPlaces = []
                    return
                }
                
                let results = response?.mapItems ?? []
                self?.processSearchResults(results, pinCoordinate: coordinate)
            }
        }
    }
    
    private func processSearchResults(_ results: [MKMapItem], pinCoordinate: CLLocationCoordinate2D) {
        let pinLocation = CLLocation(latitude: pinCoordinate.latitude, longitude: pinCoordinate.longitude)
        
        let sortedItems = results.compactMap { item -> (item: MKMapItem, distance: Double)? in
            let itemLocation = CLLocation(latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude)
            let distance = pinLocation.distance(from: itemLocation)
            
            // Only include items within 300 meters for now
            guard distance <= 300 else { return nil }
            
            return (item: item, distance: distance)
        }
        .sorted { $0.distance < $1.distance }
        
        self.nearbyPlaces = Array(sortedItems.prefix(5)).map { result in
            let distanceText = String(format: "%.0fm", result.distance)
            return NearbyPlace(
                id: UUID(),
                name: result.item.name ?? "Unknown Place",
                address: "\(formatAddress(from: result.item.placemark)) • \(distanceText)",
                coordinate: result.item.placemark.coordinate
            )
        }
    }
}
