//
//  SavePinViewModel.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-19.
//

import SwiftUI
import CoreData
import PhotosUI
import Foundation

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
        
        do {
            // Create the saved pin entity
            let savedPin = SavedPinEntity(
                context: coreDataManager.context,
                placeName: editedPlaceName.trimmingCharacters(in: .whitespacesAndNewlines),
                address: address,
                coordinate: pin.coordinate,
                notes: notes.isEmpty ? nil : notes,
                category: selectedCategory
            )
            
            // Save photos to file system and store paths
            let photoFilePaths = try savePhotosToFileSystem(for: savedPin.id)
            savedPin.photoFilePathsArray = photoFilePaths
            
            // Save attachments to file system and store paths  
            let attachmentFilePaths = try saveAttachmentsToFileSystem(for: savedPin.id)
            savedPin.attachmentFilePathsArray = attachmentFilePaths
            
            // Save to Core Data
            coreDataManager.save()
            
            print("✅ Successfully saved pin: \(savedPin.placeName)")
            
        } catch {
            errorMessage = "Failed to save pin: \(error.localizedDescription)"
            print("❌ Error saving pin: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - File Management
    
    private func savePhotosToFileSystem(for pinID: UUID) throws -> [String] {
        guard !loadedImages.isEmpty else { return [] }
        
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pinPhotosDirectory = documentsPath
            .appendingPathComponent("SavedPins")
            .appendingPathComponent(pinID.uuidString)
            .appendingPathComponent("photos")
        
        // Create directory if it doesn't exist
        try fileManager.createDirectory(at: pinPhotosDirectory, withIntermediateDirectories: true)
        
        var savedPaths: [String] = []
        
        for (index, image) in loadedImages.enumerated() {
            let fileName = "photo_\(index + 1).jpg"
            let fileURL = pinPhotosDirectory.appendingPathComponent(fileName)
            
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                try imageData.write(to: fileURL)
                savedPaths.append(fileURL.relativePath)
            }
        }
        
        return savedPaths
    }
    
    private func saveAttachmentsToFileSystem(for pinID: UUID) throws -> [String] {
        guard !attachments.isEmpty else { return [] }
        
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pinAttachmentsDirectory = documentsPath
            .appendingPathComponent("SavedPins")
            .appendingPathComponent(pinID.uuidString)
            .appendingPathComponent("attachments")
        
        // Create directory if it doesn't exist
        try fileManager.createDirectory(at: pinAttachmentsDirectory, withIntermediateDirectories: true)
        
        var savedPaths: [String] = []
        
        for attachment in attachments {
            let fileName = attachment.name
            let destinationURL = pinAttachmentsDirectory.appendingPathComponent(fileName)
            
            // Copy file from source to destination
            let accessing = attachment.url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    attachment.url.stopAccessingSecurityScopedResource()
                }
            }
            
            try fileManager.copyItem(at: attachment.url, to: destinationURL)
            savedPaths.append(destinationURL.relativePath)
        }
        
        return savedPaths
    }
}