//
//  SavedPinEntity.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-19.
//

import Foundation
import CoreData
import SwiftUI
import CoreLocation

// MARK: - SavedPinEntity Core Data Class

@objc(SavedPinEntity)
public class SavedPinEntity: NSManagedObject {
    
    // MARK: - Core Data Properties
    @NSManaged public var id: UUID
    @NSManaged public var placeName: String
    @NSManaged public var address: String
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var notes: String?
    @NSManaged public var photoFilePaths: String?
    @NSManaged public var attachmentFilePaths: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date?
    @NSManaged public var category: CategoryEntity?
    
    // MARK: - Computed Properties
    
    /// CLLocationCoordinate2D from latitude/longitude
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
    
    /// Array of photo file paths
    var photoFilePathsArray: [String] {
        get {
            guard let photoFilePaths = photoFilePaths,
                  let data = photoFilePaths.data(using: .utf8),
                  let paths = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return paths
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let jsonString = String(data: data, encoding: .utf8) {
                photoFilePaths = jsonString
            } else {
                photoFilePaths = nil
            }
        }
    }
    
    /// Array of attachment file paths
    var attachmentFilePathsArray: [String] {
        get {
            guard let attachmentFilePaths = attachmentFilePaths,
                  let data = attachmentFilePaths.data(using: .utf8),
                  let paths = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return paths
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let jsonString = String(data: data, encoding: .utf8) {
                attachmentFilePaths = jsonString
            } else {
                attachmentFilePaths = nil
            }
        }
    }
    
    /// Display text for lists
    var displayText: String {
        return placeName
    }
    
    /// Short address for display
    var shortAddress: String {
        let components = address.components(separatedBy: ", ")
        return components.prefix(2).joined(separator: ", ")
    }
    
    // MARK: - Convenience Initializer
    
    convenience init(context: NSManagedObjectContext, 
                    placeName: String, 
                    address: String, 
                    coordinate: CLLocationCoordinate2D, 
                    notes: String? = nil, 
                    category: CategoryEntity? = nil) {
        self.init(context: context)
        self.id = UUID()
        self.placeName = placeName
        self.address = address
        self.coordinate = coordinate
        self.notes = notes
        self.category = category
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Fetch Methods
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavedPinEntity> {
        return NSFetchRequest<SavedPinEntity>(entityName: "SavedPinEntity")
    }
    
    static func fetchAllSavedPins(context: NSManagedObjectContext) -> [SavedPinEntity] {
        let request: NSFetchRequest<SavedPinEntity> = SavedPinEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedPinEntity.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch saved pins: \(error)")
            return []
        }
    }
    
    static func fetchSavedPins(for category: CategoryEntity, context: NSManagedObjectContext) -> [SavedPinEntity] {
        let request: NSFetchRequest<SavedPinEntity> = SavedPinEntity.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedPinEntity.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch saved pins for category: \(error)")
            return []
        }
    }
    
    // MARK: - File Management
    
    /// Add photo file path to the array
    func addPhotoFilePath(_ path: String) {
        var paths = photoFilePathsArray
        paths.append(path)
        photoFilePathsArray = paths
    }
    
    /// Add attachment file path to the array
    func addAttachmentFilePath(_ path: String) {
        var paths = attachmentFilePathsArray
        paths.append(path)
        attachmentFilePathsArray = paths
    }
    
    /// Remove photo file path from array
    func removePhotoFilePath(_ path: String) {
        var paths = photoFilePathsArray
        paths.removeAll { $0 == path }
        photoFilePathsArray = paths
    }
    
    /// Remove attachment file path from array
    func removeAttachmentFilePath(_ path: String) {
        var paths = attachmentFilePathsArray
        paths.removeAll { $0 == path }
        attachmentFilePathsArray = paths
    }
    
    // MARK: - Update Methods
    
    func updatePin(placeName: String? = nil, 
                  notes: String? = nil, 
                  category: CategoryEntity? = nil) {
        if let placeName = placeName {
            self.placeName = placeName
        }
        if let notes = notes {
            self.notes = notes
        }
        if let category = category {
            self.category = category
        }
        self.updatedAt = Date()
    }
}