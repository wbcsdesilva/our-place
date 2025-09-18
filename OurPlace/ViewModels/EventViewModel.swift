//
//  EventViewModel.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-21.
//

import Foundation
import CoreData
import EventKit
import UserNotifications
import UIKit

@MainActor
class EventViewModel: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let coreDataManager = CoreDataManager.shared
    private let eventStore = EKEventStore()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        requestPermissions()
        clearBadgeCount()
    }
    
    private func requestPermissions() {
        requestCalendarPermission()
        requestNotificationPermission()
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
    
    private func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Notification permission error: \(error.localizedDescription)"
                } else if !granted {
                    self?.errorMessage = "Notification permission denied. Enable in Settings to receive event reminders."
                }
            }
        }
    }
    
    
    func getEventsForDate(_ date: Date) -> [EventEntity] {
        return EventEntity.fetchEventsForDate(date, context: coreDataManager.context)
    }
    
    
    func createEvent(name: String, startDate: Date, endDate: Date, reminderMinutes: Int16, isAllDay: Bool = false, savedPin: SavedPinEntity) async -> Bool {
        do {
            let newEvent = EventEntity(
                context: coreDataManager.context,
                name: name,
                startDate: startDate,
                endDate: endDate,
                isAllDay: isAllDay,
                reminderMinutes: reminderMinutes,
                savedPin: savedPin
            )

            let calendarEventID = try await createCalendarEvent(
                title: name,
                startDate: startDate,
                endDate: endDate,
                isAllDay: isAllDay,
                location: savedPin.placeName,
                notes: "Event at \(savedPin.address)"
            )
            
            newEvent.eventKitEventID = calendarEventID
            
            try await scheduleLocalNotification(for: newEvent)
            newEvent.isReminderScheduled = true
            
            try coreDataManager.context.save()

            return true
        } catch {
            await MainActor.run {
                errorMessage = "Failed to create event: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    private func createCalendarEvent(title: String, startDate: Date, endDate: Date, isAllDay: Bool, location: String, notes: String) async throws -> String? {
        return try await withCheckedThrowingContinuation { continuation in
            let event = EKEvent(eventStore: eventStore)
            event.title = title
            event.startDate = startDate
            event.endDate = endDate
            event.isAllDay = isAllDay
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
    
    // Schedule local notification for event reminder
    private func scheduleLocalNotification(for event: EventEntity) async throws {
        guard let startDate = event.startDate,
              let eventName = event.name,
              let eventId = event.id else {
            throw NSError(domain: "EventViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing event data"])
        }

        let triggerDate = startDate.addingTimeInterval(-Double(event.reminderMinutes * 60))
        
        // Don't schedule notifications for past trigger times
        if triggerDate <= Date() {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Event Reminder"
        content.body = "\(eventName) at \(event.savedPin?.placeName ?? "Unknown location") starts in \(event.reminderMinutes) minutes"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "EVENT_REMINDER"
        
        let triggerDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], 
            from: triggerDate
        )
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: eventId.uuidString, content: content, trigger: trigger)
        
        try await notificationCenter.add(request)
    }
    
    func deleteEvent(_ event: EventEntity) async {
        if let eventKitID = event.eventKitEventID {
            await deleteCalendarEvent(eventKitID: eventKitID)
        }

        if let eventId = event.id {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [eventId.uuidString])
        }

        event.delete(context: coreDataManager.context)
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
        // @FetchRequest automatically updates, so this is just for pull-to-refresh compatibility
        // Could trigger EventKit refresh here if needed
    }
    
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Show notifications even when app is in foreground
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    // Handle notification taps
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Task { @MainActor in
            clearBadgeCount()
        }
        completionHandler()
    }
    
    // Clear app badge count
    func clearBadgeCount() {
        if #available(iOS 16.0, *) {
            Task {
                try? await UNUserNotificationCenter.current().setBadgeCount(0)
            }
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }


}
