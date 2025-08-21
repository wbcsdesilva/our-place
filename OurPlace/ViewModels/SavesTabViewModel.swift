//
//  SavesTabViewModel.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-19.
//

import SwiftUI
import CoreData

class SavesTabViewModel: ObservableObject {
    @Published var savedPins: [SavedPinEntity] = []
    @Published var searchText = ""
    @Published var selectedSegment = 0 // 0 = Pins, 1 = Routes
    @Published var selectedPin: SavedPinEntity?
    @Published var showPinDetails = false
    
    private let coreDataManager = CoreDataManager.shared
    
    // Computed property for filtered pins based on search
    var filteredPins: [SavedPinEntity] {
        if searchText.isEmpty {
            return savedPins
        } else {
            return savedPins.filter { pin in
                pin.placeName.localizedCaseInsensitiveContains(searchText) ||
                pin.address.localizedCaseInsensitiveContains(searchText) ||
                pin.category?.name.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    init() {
        loadSavedPins()
    }
    
    func loadSavedPins() {
        savedPins = SavedPinEntity.fetchAllSavedPins(context: coreDataManager.context)
    }
    
    func refreshPins() {
        loadSavedPins()
    }
    
    func showPinDetails(_ pin: SavedPinEntity) {
        selectedPin = pin
        showPinDetails = true
    }
    
    // Format date for display
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}