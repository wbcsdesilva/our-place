//
//  RouteStopEntity.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-15.
//

import Foundation
import CoreData

// MARK: - RouteStopEntity Core Data Class

@objc(RouteStopEntity)
public class RouteStopEntity: NSManagedObject {
    
    // MARK: - Core Data Properties
    @NSManaged public var id: UUID
    @NSManaged public var order: Int16
    @NSManaged public var route: RouteEntity?
    @NSManaged public var savedPin: SavedPinEntity?
    
    // MARK: - Computed Properties
    
    /// Get the saved pin's place name safely
    var placeName: String {
        return savedPin?.placeName ?? "Unknown Place"
    }
    
    /// Get the saved pin's address safely
    var address: String {
        return savedPin?.address ?? "Unknown Address"
    }
    
    /// Get the saved pin's coordinate safely
    var coordinate: (latitude: Double, longitude: Double) {
        return (savedPin?.latitude ?? 0.0, savedPin?.longitude ?? 0.0)
    }
    
    /// Get the category safely
    var category: CategoryEntity? {
        return savedPin?.category
    }
    
    // MARK: - Convenience Initializer
    
    convenience init(context: NSManagedObjectContext, 
                    savedPin: SavedPinEntity, 
                    order: Int16) {
        self.init(context: context)
        self.id = UUID()
        self.savedPin = savedPin
        self.order = order
    }
    
    // MARK: - Fetch Methods
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RouteStopEntity> {
        return NSFetchRequest<RouteStopEntity>(entityName: "RouteStopEntity")
    }
    
    /// Fetch all route stops for a specific route
    static func fetchStopsForRoute(_ route: RouteEntity, context: NSManagedObjectContext) -> [RouteStopEntity] {
        let request: NSFetchRequest<RouteStopEntity> = RouteStopEntity.fetchRequest()
        request.predicate = NSPredicate(format: "route == %@", route)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RouteStopEntity.order, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch route stops: \(error)")
            return []
        }
    }
    
    /// Update the order of this stop
    func updateOrder(_ newOrder: Int16, context: NSManagedObjectContext) {
        order = newOrder
        route?.updatedAt = Date()
        
        do {
            try context.save()
        } catch {
            print("Failed to update stop order: \(error)")
        }
    }
}