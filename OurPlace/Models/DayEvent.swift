//
//  DayEvent.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-17.
//

import Foundation
import CoreData
import EventKit

struct DayEvent: Identifiable {
    enum Source {
        case app
        case calendar
    }

    let id: String
    let title: String
    let start: Date
    let end: Date?
    let location: String?
    let source: Source
    let isAllDay: Bool
    let ekIdentifier: String?
    let coreDataURI: String?

    var duration: TimeInterval? {
        guard let end = end else { return nil }
        return end.timeIntervalSince(start)
    }

    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        if isAllDay {
            return "All day"
        }

        if let end = end {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        } else {
            return formatter.string(from: start)
        }
    }
}

extension DayEvent {
    // Create from Core Data EventEntity
    static func from(eventEntity: EventEntity) -> DayEvent? {
        guard let name = eventEntity.name,
              let startDate = eventEntity.startDate else {
            return nil
        }

        let objectID = eventEntity.objectID

        return DayEvent(
            id: objectID.uriRepresentation().absoluteString,
            title: name,
            start: startDate,
            end: eventEntity.endDate,
            location: eventEntity.savedPin?.placeName,
            source: .app,
            isAllDay: eventEntity.isAllDay,
            ekIdentifier: eventEntity.eventKitEventID,
            coreDataURI: objectID.uriRepresentation().absoluteString
        )
    }

    // Create from EventKit EKEvent
    static func from(ekEvent: EKEvent) -> DayEvent {
        return DayEvent(
            id: ekEvent.eventIdentifier,
            title: ekEvent.title ?? "Untitled Event",
            start: ekEvent.startDate,
            end: ekEvent.endDate,
            location: ekEvent.location,
            source: .calendar,
            isAllDay: ekEvent.isAllDay,
            ekIdentifier: ekEvent.eventIdentifier,
            coreDataURI: nil
        )
    }
}

// MARK: - Deduplication and Merging Logic
extension Array where Element == DayEvent {
    // Remove duplicates, prioritizing app events over calendar events
    func deduplicated() -> [DayEvent] {
        var seen = Set<String>()
        var result: [DayEvent] = []

        // First pass: add all app events
        for event in self where event.source == .app {
            if let ekIdentifier = event.ekIdentifier {
                seen.insert(ekIdentifier)
            }
            result.append(event)
        }

        // Second pass: add calendar events that don't have matching app events
        for event in self where event.source == .calendar {
            if let ekIdentifier = event.ekIdentifier, !seen.contains(ekIdentifier) {
                result.append(event)
            }
        }

        return result.sorted { $0.start < $1.start }
    }
}