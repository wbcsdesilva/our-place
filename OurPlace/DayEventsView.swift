//
//  DayEventsView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-17.
//

import SwiftUI
import CoreData

struct DayEventsView: View {
    let date: Date

    @StateObject private var eventKitService = EventKitService.shared
    @ObservedObject var eventViewModel: EventViewModel
    @State private var dayEvents: [DayEvent] = []
    @State private var isLoading = true
    @State private var hasRequestedAccess = false
    @State private var eventToDelete: DayEvent?
    @State private var showDeleteConfirmation = false

    private let coreDataManager = CoreDataService.shared

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }

    private var dayBounds: (start: Date, end: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return (startOfDay, endOfDay)
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Loading events...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !eventKitService.hasCalendarAccess && hasRequestedAccess {
                calendarAccessDeniedView
            } else if dayEvents.isEmpty {
                emptyStateView
            } else {
                eventsList
            }
        }
        .navigationTitle(dateFormatter.string(from: date))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadDayEvents()
        }
        .onReceive(eventKitService.$shouldRefresh) { _ in
            loadDayEvents()
        }
        .refreshable {
            loadDayEvents()
        }
        .alert("Delete Event", isPresented: $showDeleteConfirmation, presenting: eventToDelete) { event in
            Button("Delete", role: .destructive) {
                deleteEvent(event)
            }
            Button("Cancel", role: .cancel) { }
        } message: { event in
            Text("Are you sure you want to delete '\(event.title)'? This action cannot be undone.")
        }
    }

    private var eventsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(dayEvents) { event in
                    DayEventRow(event: event)
                        .contextMenu {
                            if event.source == .app {
                                Button("Delete Event", systemImage: "trash", role: .destructive) {
                                    eventToDelete = event
                                    showDeleteConfirmation = true
                                }
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Events",
            systemImage: "calendar",
            description: Text("No events are scheduled for this day.")
        )
    }

    private var calendarAccessDeniedView: some View {
        ContentUnavailableView {
            Label("Calendar Access Denied", systemImage: "calendar.badge.exclamationmark")
        } description: {
            Text("To view events from your Calendar app, please enable calendar access in Settings.")
        } actions: {
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func loadDayEvents() {
        isLoading = true

        Task {
            // Request calendar access if needed
            if !hasRequestedAccess {
                _ = await eventKitService.requestAccessIfNeeded()
                await MainActor.run {
                    hasRequestedAccess = true
                }
            }

            let bounds = dayBounds
            var allEvents: [DayEvent] = []

            // Load Core Data events
            let coreDataEvents = EventEntity.fetchEventsForDate(date, context: coreDataManager.context)
            let appEvents = coreDataEvents.compactMap { DayEvent.from(eventEntity: $0) }
            allEvents.append(contentsOf: appEvents)

            // Load EventKit events if access is granted
            if eventKitService.hasCalendarAccess {
                let ekEvents = eventKitService.fetchEvents(from: bounds.start, to: bounds.end)
                let calendarEvents = ekEvents.map { DayEvent.from(ekEvent: $0) }
                allEvents.append(contentsOf: calendarEvents)
            }

            // Deduplicate and sort
            let deduplicatedEvents = allEvents.deduplicated()

            await MainActor.run {
                dayEvents = deduplicatedEvents
                isLoading = false
            }
        }
    }

    private func deleteEvent(_ dayEvent: DayEvent) {
        Task {
            if let coreDataURI = dayEvent.coreDataURI,
               let url = URL(string: coreDataURI),
               let objectID = coreDataManager.context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url),
               let eventEntity = try? coreDataManager.context.existingObject(with: objectID) as? EventEntity {

                await eventViewModel.deleteEvent(eventEntity)
                loadDayEvents()
            }
        }
    }
}

struct DayEventRow: View {
    let event: DayEvent

    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(alignment: .leading, spacing: 2) {
                Text(event.formattedTimeRange)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                if event.isAllDay {
                    Spacer()
                }
            }
            .frame(width: 80, alignment: .leading)

            // Event content
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if let location = event.location, !location.isEmpty {
                    Label(location, systemImage: "location")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Source indicator
                HStack {
                    Label(
                        event.source == .app ? "OurPlace Event" : "Calendar Event",
                        systemImage: event.source == .app ? "mappin.circle.fill" : "calendar"
                    )
                    .font(.caption)
                    .foregroundColor(event.source == .app ? .blue : .secondary)

                    Spacer()
                }
            }

            Spacer()
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(event.source == .app ? Color.blue.opacity(0.1) : Color(.systemGray6))
        }
        .overlay(alignment: .leading) {
            if event.source == .app {
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 4)
                    .clipShape(
                        .rect(
                            topLeadingRadius: 12,
                            bottomLeadingRadius: 12,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 0
                        )
                    )
            }
        }
    }
}

#Preview {
    NavigationStack {
        DayEventsView(date: Date(), eventViewModel: EventViewModel())
    }
}