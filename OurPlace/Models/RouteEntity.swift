//
//  RouteEntity.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-15.
//

import Foundation
import CoreData

// MARK: - RouteEntity Core Data Class

@objc(RouteEntity)
public class RouteEntity: NSManagedObject {
    
    // MARK: - Core Data Properties
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date?
    @NSManaged public var totalDistance: Double
    @NSManaged public var stops: NSSet?
    
    // MARK: - Computed Properties
    
    /// Get ordered stops for this route
    var orderedStops: [RouteStopEntity] {
        let stopsSet = stops as? Set<RouteStopEntity> ?? []
        return stopsSet.sorted { $0.order < $1.order }
    }
    
    /// Get formatted creation date
    var formattedCreatedAt: String {
        return DateFormatters.relative.string(from: createdAt)
    }
    
    /// Get stop count
    var stopCount: Int {
        return orderedStops.count
    }
    
    /// Get formatted distance
    var formattedDistance: String {
        let distanceInKm = totalDistance / 1000.0
        return String(format: "%.1fkm", distanceInKm)
    }
    
    // MARK: - Convenience Initializer
    
    convenience init(context: NSManagedObjectContext, 
                    name: String) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.totalDistance = 0.0
    }
    
    // MARK: - Fetch Methods
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RouteEntity> {
        return NSFetchRequest<RouteEntity>(entityName: "RouteEntity")
    }
    
    /// Create a new route in Core Data
    static func createRoute(
        name: String,
        stops: [RouteStop],
        context: NSManagedObjectContext
    ) -> RouteEntity? {
        let route = RouteEntity(context: context, name: name)
        
        // Create route stops
        for routeStop in stops {
            let stopEntity = RouteStopEntity(context: context, 
                                           savedPin: routeStop.savedPin, 
                                           order: Int16(routeStop.order))
            stopEntity.route = route
        }
        
        do {
            try context.save()
            return route
        } catch {
            print("Failed to create route: \(error)")
            return nil
        }
    }
    
    /// Fetch all routes from Core Data
    static func fetchAllRoutes(context: NSManagedObjectContext) -> [RouteEntity] {
        let request: NSFetchRequest<RouteEntity> = RouteEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RouteEntity.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch routes: \(error)")
            return []
        }
    }
    
    /// Delete a route from Core Data
    func deleteRoute(context: NSManagedObjectContext) {
        // Delete associated stops first
        for stop in orderedStops {
            context.delete(stop)
        }
        
        // Delete the route
        context.delete(self)
        
        do {
            try context.save()
        } catch {
            print("Failed to delete route: \(error)")
        }
    }
    
    /// Update route distance (can be called after route creation)
    func updateTotalDistance(_ distance: Double, context: NSManagedObjectContext) {
        totalDistance = distance
        updatedAt = Date()
        
        do {
            try context.save()
        } catch {
            print("Failed to update route distance: \(error)")
        }
    }
}

// MARK: - Generated accessors for stops

extension RouteEntity {
    
    @objc(addStopsObject:)
    @NSManaged public func addToStops(_ value: RouteStopEntity)
    
    @objc(removeStopsObject:)
    @NSManaged public func removeFromStops(_ value: RouteStopEntity)
    
    @objc(addStops:)
    @NSManaged public func addToStops(_ values: NSSet)
    
    @objc(removeStops:)
    @NSManaged public func removeFromStops(_ values: NSSet)
}