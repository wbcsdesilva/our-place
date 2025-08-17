//
//  MapTabView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-01-XX.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapTabView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var cameraPosition = MapCameraPosition.region(
        // TODO: Starting map region and camera position. This is currently set to California, change it to somehwere in Sri Lanka
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.4419, longitude: -122.1419),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    
    @State private var droppedPin: DroppedPin?
    @State private var showPinDetails = false
    @State private var reverseGeocodedAddress = ""
    @State private var nearbyPlaces: [NearbyPlace] = []
    @State private var isLoadingNearbyPlaces = false
    @State private var currentMapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.4419, longitude: -122.1419),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    if let userLocation = locationManager.userLocation {
                        Annotation("My Location", coordinate: userLocation) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .shadow(radius: 3)
                        }
                    }
                    
                    if let pin = droppedPin {
                        Annotation("Dropped Pin", coordinate: pin.coordinate, anchor: .bottom) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.red)
                                .font(.system(size: 30))
                                .shadow(radius: 3)
                        }
                    }
                }
                .mapControlVisibility(.hidden)
                .onMapCameraChange(frequency: .continuous) { context in
                    currentMapRegion = context.region
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    if let coordinate = proxy.convert(location, from: .local) {
                        dropPinAtCoordinate(coordinate)
                    }
                }
            }
            
            VStack {
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        centerOnUserLocation()
                    }) {
                        Image(systemName: "rotate.3d.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                            .frame(width: 56, height: 56)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .sheet(isPresented: $showPinDetails) {
            PinDetailsSheet(
                pin: droppedPin,
                address: reverseGeocodedAddress,
                nearbyPlaces: nearbyPlaces,
                isLoading: isLoadingNearbyPlaces,
                onSnapToPlace: snapPinToPlace,
                onSaveAsIs: savePinAsIs,
                onDismiss: dismissPinDetails
            )
        }
        .onAppear {
            locationManager.requestPermission()
        }
        .onChange(of: locationManager.userLocation) { _, newLocation in
            if let location = newLocation {
                updateRegion(to: location)
            }
        }
    }
    
    private func centerOnUserLocation() {
        if let userLocation = locationManager.userLocation {
            withAnimation(.easeInOut(duration: 1.0)) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
    }
    
    private func updateRegion(to location: CLLocationCoordinate2D) {
        let newRegion = MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        cameraPosition = .region(newRegion)
        currentMapRegion = newRegion
    }
    
    // MARK: - Pin Dropping Functions
    
    private func dropPinAtCoordinate(_ coordinate: CLLocationCoordinate2D) {
        let pin = DroppedPin(
            id: UUID(),
            coordinate: coordinate,
            timestamp: Date()
        )
        
        droppedPin = pin
        reverseGeocode(coordinate: coordinate)
        searchNearbyPlaces(coordinate: coordinate)
        showPinDetails = true
    }
    
    private func getCurrentMapRegion() -> MKCoordinateRegion {
        return currentMapRegion
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    self.reverseGeocodedAddress = formatAddress(from: placemark)
                } else {
                    self.reverseGeocodedAddress = "\(coordinate.latitude), \(coordinate.longitude)"
                }
            }
        }
    }
    
    private func searchNearbyPlaces(coordinate: CLLocationCoordinate2D) {
        isLoadingNearbyPlaces = true
        nearbyPlaces = []
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "restaurant, store, business"
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                self.isLoadingNearbyPlaces = false
                
                if let response = response {
                    self.nearbyPlaces = response.mapItems.prefix(5).map { item in
                        NearbyPlace(
                            id: UUID(),
                            name: item.name ?? "Unknown",
                            address: formatAddress(from: item.placemark),
                            coordinate: item.placemark.coordinate
                        )
                    }
                }
            }
        }
    }
    
    private func snapPinToPlace(_ place: NearbyPlace) {
        droppedPin?.coordinate = place.coordinate
        reverseGeocodedAddress = place.address
        showPinDetails = false
    }
    
    private func savePinAsIs() {
        print("Saving pin at: \(droppedPin?.coordinate.latitude ?? 0), \(droppedPin?.coordinate.longitude ?? 0)")
        showPinDetails = false
    }
    
    private func dismissPinDetails() {
        showPinDetails = false
        droppedPin = nil
        nearbyPlaces = []
        reverseGeocodedAddress = ""
    }
}

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            break
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

// MARK: - Data Models

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

// MARK: - Pin Details Sheet

struct PinDetailsSheet: View {
    let pin: DroppedPin?
    let address: String
    let nearbyPlaces: [NearbyPlace]
    let isLoading: Bool
    let onSnapToPlace: (NearbyPlace) -> Void
    let onSaveAsIs: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(address.isEmpty ? "Loading address..." : address)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let pin = pin {
                        Text("\(pin.coordinate.latitude, specifier: "%.4f"), \(pin.coordinate.longitude, specifier: "%.4f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Nearby places you may have meant")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Finding nearby places...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(nearbyPlaces) { place in
                            NearbyPlaceRow(place: place) {
                                onSnapToPlace(place)
                            }
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                Button(action: onSaveAsIs) {
                    Text("Save pin as is")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Pin Dropped")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel", action: onDismiss)
                }
            }
        }
    }
}

struct NearbyPlaceRow: View {
    let place: NearbyPlace
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(place.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text("\(place.coordinate.latitude, specifier: "%.4f"), \(place.coordinate.longitude, specifier: "%.4f")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onTap) {
                Image(systemName: "link")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                    .frame(width: 32, height: 32)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Helper Functions

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

// MARK: - Extensions

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        let epsilon = 1e-10
        return abs(lhs.latitude - rhs.latitude) < epsilon && 
               abs(lhs.longitude - rhs.longitude) < epsilon
    }
}

#Preview {
    MapTabView()
}
