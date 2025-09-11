//
//  EventViewModel.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-21.
//

import Foundation
import CoreData
import EventKit

@MainActor
class EventViewModel: ObservableObject {
    @Published var events: [EventEntity] = []
    @Published var upcomingEvents: [EventEntity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let coreDataManager = CoreDataManager.shared
    private let eventStore = EKEventStore()
    
    init() {
        loadEvents()
        requestPermissions()
    }
    
    private func requestPermissions() {
        requestCalendarPermission()
    }
    
    private func requestCalendarPermission() {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = "Calendar access error: \(error.localizedDescription)"
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = "Calendar access error: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    
    func loadEvents() {
        isLoading = true
        
        events = EventEntity.fetchAllEvents(context: coreDataManager.context)
        upcomingEvents = EventEntity.fetchUpcomingEvents(context: coreDataManager.context)
        
        isLoading = false
    }
    
    func getEventsForDate(_ date: Date) -> [EventEntity] {
        return EventEntity.fetchEventsForDate(date, context: coreDataManager.context)
    }
    
    func getDatesWithEvents(for month: Date) -> Set<Date> {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let endOfMonth = calendar.dateInterval(of: .month, for: month)?.end ?? month
        
        let monthEvents = events.filter { event in
            guard let eventDate = event.eventDate else { return false }
            return eventDate >= startOfMonth && eventDate <= endOfMonth
        }
        
        let dates = Set<Date>(monthEvents.compactMap { event in
            guard let eventDate = event.eventDate else { return nil }
            return calendar.startOfDay(for: eventDate)
        })
        return dates
    }
    
    func createEvent(name: String, eventDate: Date, reminderMinutes: Int16, savedPin: SavedPinEntity) async -> Bool {
        do {
            let newEvent = EventEntity(
                context: coreDataManager.context,
                name: name,
                eventDate: eventDate,
                reminderMinutes: reminderMinutes,
                savedPin: savedPin
            )
            
            let calendarEventID = try await createCalendarEvent(
                title: name,
                date: eventDate,
                location: savedPin.placeName,
                notes: "Event at \(savedPin.address)"
            )
            
            newEvent.eventKitEventID = calendarEventID
            
            try coreDataManager.context.save()
            
            await MainActor.run {
                loadEvents()
            }
            
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Failed to create event: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    private func createCalendarEvent(title: String, date: Date, location: String, notes: String) async throws -> String? {
        return try await withCheckedThrowingContinuation { continuation in
            let event = EKEvent(eventStore: eventStore)
            event.title = title
            event.startDate = date
            event.endDate = date.addingTimeInterval(3600) // 1 hour duration
            event.location = location
            event.notes = notes
            event.calendar = eventStore.defaultCalendarForNewEvents
            
            do {
                try eventStore.save(event, span: .thisEvent)
                continuation.resume(returning: event.eventIdentifier)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    
    func deleteEvent(_ event: EventEntity) async {
        if let eventKitID = event.eventKitEventID {
            await deleteCalendarEvent(eventKitID: eventKitID)
        }
        
        event.delete(context: coreDataManager.context)
        
        await MainActor.run {
            loadEvents()
        }
    }
    
    private func deleteCalendarEvent(eventKitID: String) async {
        if let calendarEvent = eventStore.event(withIdentifier: eventKitID) {
            do {
                try eventStore.remove(calendarEvent, span: .thisEvent)
            } catch {
                errorMessage = "Failed to remove calendar event: \(error.localizedDescription)"
            }
        }
    }
    
    func refreshEvents() {
        loadEvents()
    }
    
}