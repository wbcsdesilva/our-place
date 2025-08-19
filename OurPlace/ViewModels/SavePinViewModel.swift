//
//  SavePinViewModel.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-19.
//

import SwiftUI
import CoreData
import PhotosUI

class SavePinViewModel: ObservableObject {
    @Published var categories: [CategoryEntity] = []
    @Published var selectedCategory: CategoryEntity?
    @Published var editedPlaceName: String
    @Published var notes = ""
    @Published var selectedPhotos: [PhotosPickerItem] = []
    @Published var loadedImages: [UIImage] = []
    @Published var attachments: [AttachmentItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let coreDataManager = CoreDataManager.shared
    let pin: DroppedPin
    let originalPlaceName: String
    let address: String
    
    init(pin: DroppedPin, placeName: String, address: String) {
        self.pin = pin
        self.originalPlaceName = placeName
        self.address = address
        self.editedPlaceName = placeName
        
        loadCategories()
    }
    
    func loadCategories() {
        categories = CategoryEntity.fetchAllCategories(context: coreDataManager.context)
        
        // Set default selection to first category if none selected
        if selectedCategory == nil && !categories.isEmpty {
            selectedCategory = categories.first
        }
    }
    
    func selectCategory(_ category: CategoryEntity) {
        selectedCategory = category
    }
    
    func onCategoryCreated(_ newCategory: CategoryEntity) {
        // Reload categories to include the new one
        loadCategories()
        // Auto-select the newly created category
        selectedCategory = newCategory
    }
    
    func savePin() {
        guard let selectedCategory = selectedCategory else {
            errorMessage = "Please select a category"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement actual pin saving to Core Data
        print("Saving pin with category: \(selectedCategory.displayText)")
        print("Place name: \(editedPlaceName)")
        print("Notes: \(notes)")
        print("Photos count: \(loadedImages.count)")
        print("Attachments count: \(attachments.count)")
        
        isLoading = false
        
        // For now, just simulate successful save
        // In the future, this would save to Core Data and return success/failure
    }
}