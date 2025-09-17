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
    @Published var editedPlaceName: String
    @Published var notes = ""
    @Published var selectedPhotos: [PhotosPickerItem] = []
    @Published var loadedImages: [UIImage] = []
    @Published var attachments: [AttachmentItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var savedSuccessfully = false

    let pin: DroppedPin
    let originalPlaceName: String
    let address: String

    init(pin: DroppedPin, placeName: String, address: String) {
        self.pin = pin
        self.originalPlaceName = placeName
        self.address = address
        self.editedPlaceName = placeName
    }
    
    func savePin(selectedCategory: CategoryEntity?, context: NSManagedObjectContext) {
        guard let selectedCategory = selectedCategory else {
            errorMessage = "Please select a category"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Create the saved pin entity
            let savedPin = SavedPinEntity(
                context: context,
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
            try context.save()
            
            print("✅ Successfully saved pin: \(savedPin.placeName)")
            savedSuccessfully = true
            
        } catch {
            errorMessage = "Failed to save pin: \(error.localizedDescription)"
            print("❌ Error saving pin: \(error)")
            savedSuccessfully = false
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
                // Store relative path from Documents directory for portability
                let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                let relativePath = fileURL.path.replacingOccurrences(of: documentsPath.path + "/", with: "")
                savedPaths.append(relativePath)
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
            // Store relative path from Documents directory for portability
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let relativePath = destinationURL.path.replacingOccurrences(of: documentsPath.path + "/", with: "")
            savedPaths.append(relativePath)
        }
        
        return savedPaths
    }
}