//
//  MapSearchViewModel.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-20.
//

import SwiftUI
import MapKit
import CoreLocation
import CoreData

// MARK: - Search Result Types

struct SavedPinSearchResult: Identifiable {
    let id = UUID()
    let savedPin: SavedPinEntity
}

struct POISearchResult: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let distance: Double?
}

// MARK: - Map Search View Model

class MapSearchViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchText = ""
    @Published var isSearching = false
    @Published var savedPinResults: [SavedPinSearchResult] = []
    @Published var poiResults: [POISearchResult] = []
    @Published var isLoadingPOIs = false
    
    // MARK: - Private Properties
    private let coreDataManager = CoreDataService.shared
    private var searchTask: Task<Void, Never>?
    private var currentUserLocation: CLLocationCoordinate2D?
    
    // MARK: - Computed Properties
    var hasResults: Bool {
        !savedPinResults.isEmpty || !poiResults.isEmpty
    }
    
    var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    
    // MARK: - Public Methods
    
    func updateSearchText(_ text: String) {
        searchText = text
        
        // Cancel previous search task
        searchTask?.cancel()
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedText.isEmpty {
            clearResults()
            return
        }
        
        
        // Debounce search with 300ms delay
        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            
            if !Task.isCancelled && self.searchText == text {
                await performSearch(query: trimmedText)
            }
        }
    }
    
    func setUserLocation(_ location: CLLocationCoordinate2D) {
        currentUserLocation = location
    }
    
    func clearResults() {
        savedPinResults = []
        poiResults = []
        isLoadingPOIs = false
        isSearching = false
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func performSearch(query: String) async {
        isSearching = true
        isLoadingPOIs = true
        
        // Search saved pins
        searchSavedPins(query: query)
        
        // Search POIs
        await searchPOIs(query: query)
        
        isSearching = false
        isLoadingPOIs = false
    }
    
    @MainActor
    private func searchSavedPins(query: String) {
        let savedPins = SavedPinEntity.fetchAllSavedPins(context: coreDataManager.context)
        
        let filteredPins = savedPins.filter { pin in
            pin.placeName.localizedCaseInsensitiveContains(query) ||
            pin.shortAddress.localizedCaseInsensitiveContains(query) ||
            pin.address.localizedCaseInsensitiveContains(query) ||
            pin.category?.name.localizedCaseInsensitiveContains(query) == true
        }
        
        self.savedPinResults = filteredPins.map { SavedPinSearchResult(savedPin: $0) }
    }
    
    private func searchPOIs(query: String) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        // Use user location as region if available
        if let userLocation = currentUserLocation {
            request.region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            let results = response.mapItems.prefix(10) // Limit to 10 results
            
            let poiResults: [POISearchResult] = results.compactMap { mapItem in
                let distance = currentUserLocation.map { userLoc in
                    let userLocation = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
                    let itemLocation = CLLocation(
                        latitude: mapItem.placemark.coordinate.latitude,
                        longitude: mapItem.placemark.coordinate.longitude
                    )
                    return userLocation.distance(from: itemLocation)
                }
                
                return POISearchResult(
                    name: mapItem.name ?? "Unknown Place",
                    address: formatAddress(from: mapItem.placemark),
                    coordinate: mapItem.placemark.coordinate,
                    distance: distance
                )
            }
            
            await MainActor.run {
                self.poiResults = poiResults
            }
        } catch {
            await MainActor.run {
                self.poiResults = []
            }
        }
    }
}
