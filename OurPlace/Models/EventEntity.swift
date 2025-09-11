//
//  EventEntity.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-21.
//

import Foundation
import CoreData
import EventKit

@objc(EventEntity)
public class EventEntity: NSManagedObject {
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var eventDate: Date?
    @NSManaged public var reminderMinutes: Int16
    @NSManaged public var eventKitEventID: String?
    @NSManaged public var isReminderScheduled: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var savedPin: SavedPinEntity?
    
    convenience init(context: NSManagedObjectContext, name: String, eventDate: Date, reminderMinutes: Int16, savedPin: SavedPinEntity) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.eventDate = eventDate
        self.reminderMinutes = reminderMinutes
        self.savedPin = savedPin
        self.isReminderScheduled = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var isUpcoming: Bool {
        guard let eventDate = eventDate else { return false }
        return eventDate > Date()
    }
    
    var timeUntilEvent: String {
        guard let eventDate = eventDate else { return "Unknown time" }
        
        let now = Date()
        let timeInterval = eventDate.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            return "Past event"
        }
        
        let days = Int(timeInterval / (24 * 60 * 60))
        let hours = Int((timeInterval.truncatingRemainder(dividingBy: 24 * 60 * 60)) / (60 * 60))
        
        if days > 0 {
            return "in \(days) day\(days == 1 ? "" : "s")"
        } else if hours > 0 {
            return "in \(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 60 * 60)) / 60)
            return "in \(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
    
    var formattedDateTime: String {
        guard let eventDate = eventDate else { return "Unknown date" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy • hh:mma"
        return formatter.string(from: eventDate)
    }
    
    var reminderTime: Date {
        guard let eventDate = eventDate else { return Date() }
        return eventDate.addingTimeInterval(-Double(reminderMinutes * 60))
    }
    
    static func fetchAllEvents(context: NSManagedObjectContext) -> [EventEntity] {
        let request: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \EventEntity.eventDate, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching events: \(error)")
            return []
        }
    }
    
    static func fetchUpcomingEvents(context: NSManagedObjectContext) -> [EventEntity] {
        let request: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
        request.predicate = NSPredicate(format: "eventDate > %@", Date() as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \EventEntity.eventDate, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching upcoming events: \(error)")
            return []
        }
    }
    
    static func fetchEventsForDate(_ date: Date, context: NSManagedObjectContext) -> [EventEntity] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
        request.predicate = NSPredicate(format: "eventDate >= %@ AND eventDate < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \EventEntity.eventDate, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching events for date: \(error)")
            return []
        }
    }
    
    static func fetchEventsForSavedPin(_ savedPin: SavedPinEntity, context: NSManagedObjectContext) -> [EventEntity] {
        let request: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
        request.predicate = NSPredicate(format: "savedPin == %@", savedPin)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \EventEntity.eventDate, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching events for saved pin: \(error)")
            return []
        }
    }
    
    func delete(context: NSManagedObjectContext) {
        context.delete(self)
        
        do {
            try context.save()
        } catch {
            print("Error deleting event: \(error)")
        }
    }
}

extension EventEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<EventEntity> {
        return NSFetchRequest<EventEntity>(entityName: "EventEntity")
    }
}