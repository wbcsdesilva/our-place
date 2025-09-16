//
//  UserProfileEntity.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-16.
//

import Foundation
import CoreData
import SwiftUI

// MARK: - UserProfileEntity Core Data Class

@objc(UserProfileEntity)
public class UserProfileEntity: NSManagedObject {

    // MARK: - Core Data Properties
    @NSManaged public var id: UUID
    @NSManaged public var firebaseUID: String?
    @NSManaged public var displayName: String
    @NSManaged public var bio: String?
    @NSManaged public var profilePhotoFileName: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date

    // MARK: - Computed Properties

    /// Profile image file path (reconstructed from filename)
    var profileImagePath: String? {
        guard let fileName = profilePhotoFileName else { return nil }
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let profileImagesPath = documentsPath.appendingPathComponent("ProfileImages")
        return profileImagesPath.appendingPathComponent(fileName).path
    }

    /// Profile image URL for SwiftUI
    var profileImageURL: URL? {
        guard let path = profileImagePath else { return nil }
        return URL(fileURLWithPath: path)
    }

    /// Check if profile has a photo
    var hasProfilePhoto: Bool {
        return profilePhotoFileName != nil && !profilePhotoFileName!.isEmpty
    }

    /// Display initials for avatar fallback
    var initials: String {
        let names = displayName.components(separatedBy: " ")
        let firstInitial = names.first?.prefix(1).uppercased() ?? ""
        let lastInitial = names.count > 1 ? names.last?.prefix(1).uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }

    // MARK: - Convenience Initializer

    convenience init(context: NSManagedObjectContext,
                    displayName: String,
                    firebaseUID: String? = nil,
                    bio: String? = nil) {
        self.init(context: context)
        self.id = UUID()
        self.firebaseUID = firebaseUID
        self.displayName = displayName
        self.bio = bio
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Fetch Methods

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfileEntity> {
        return NSFetchRequest<UserProfileEntity>(entityName: "UserProfileEntity")
    }

    /// Fetch profile by Firebase UID
    static func fetchProfile(for firebaseUID: String, context: NSManagedObjectContext) -> UserProfileEntity? {
        let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        request.predicate = NSPredicate(format: "firebaseUID == %@", firebaseUID)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch profile for Firebase UID: \(error)")
            return nil
        }
    }

    /// Fetch the current user's profile (assumes single profile per app - legacy)
    static func fetchCurrentProfile(context: NSManagedObjectContext) -> UserProfileEntity? {
        let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserProfileEntity.createdAt, ascending: true)]

        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch current profile: \(error)")
            return nil
        }
    }

    /// Get or create profile for Firebase user
    static func getProfile(for firebaseUID: String, context: NSManagedObjectContext, defaultName: String = "User") -> UserProfileEntity {
        if let existingProfile = fetchProfile(for: firebaseUID, context: context) {
            return existingProfile
        } else {
            return UserProfileEntity(context: context, displayName: defaultName, firebaseUID: firebaseUID)
        }
    }

    /// Create or get the current user profile (legacy method)
    static func getCurrentProfile(context: NSManagedObjectContext, defaultName: String = "User") -> UserProfileEntity {
        if let existingProfile = fetchCurrentProfile(context: context) {
            return existingProfile
        } else {
            return UserProfileEntity(context: context, displayName: defaultName)
        }
    }

    // MARK: - Update Methods

    func updateProfile(displayName: String? = nil,
                      bio: String? = nil) {
        if let displayName = displayName {
            self.displayName = displayName
        }
        if let bio = bio {
            self.bio = bio
        }
        self.updatedAt = Date()
    }

    // MARK: - Photo Management

    /// Save profile photo and update filename
    func saveProfilePhoto(_ image: UIImage) -> Bool {
        // Create ProfileImages directory if it doesn't exist
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let profileImagesPath = documentsPath.appendingPathComponent("ProfileImages")

        do {
            try FileManager.default.createDirectory(at: profileImagesPath, withIntermediateDirectories: true)
        } catch {
            print("Failed to create ProfileImages directory: \(error)")
            return false
        }

        // Generate unique filename
        let fileName = "profile_\(UUID().uuidString).jpg"
        let fileURL = profileImagesPath.appendingPathComponent(fileName)

        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to JPEG data")
            return false
        }

        // Save image file
        do {
            try imageData.write(to: fileURL)

            // Delete old profile photo if exists
            if let oldFileName = profilePhotoFileName {
                let oldFileURL = profileImagesPath.appendingPathComponent(oldFileName)
                try? FileManager.default.removeItem(at: oldFileURL)
            }

            // Update filename in Core Data
            self.profilePhotoFileName = fileName
            self.updatedAt = Date()

            return true
        } catch {
            print("Failed to save profile image: \(error)")
            return false
        }
    }

    /// Delete profile photo
    func deleteProfilePhoto() {
        guard let fileName = profilePhotoFileName else { return }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let profileImagesPath = documentsPath.appendingPathComponent("ProfileImages")
        let fileURL = profileImagesPath.appendingPathComponent(fileName)

        // Delete file
        try? FileManager.default.removeItem(at: fileURL)

        // Clear filename from Core Data
        self.profilePhotoFileName = nil
        self.updatedAt = Date()
    }
}