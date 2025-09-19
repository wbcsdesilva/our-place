//
//  EventsTabView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-21.
//

import SwiftUI
import CoreData
import EventKit

enum UpcomingEvent: Identifiable {
    case app(EventEntity)
    case external(title: String, location: String?, formattedTimeRange: String, isAllDay: Bool, ekIdentifier: String?)

    var id: String {
        switch self {
        case .app(let event):
            return event.id?.uuidString ?? UUID().uuidString
        case .external(let title, let location, let formattedTimeRange, _, let ekIdentifier):
            return ekIdentifier ?? "\(title)-\(location ?? "")-\(formattedTimeRange)"
        }
    }

    var title: String {
        switch self {
        case .app(let event):
            return event.name ?? "Unknown Event"
        case .external(let title, _, _, _, _):
            return title
        }
    }

    var location: String? {
        switch self {
        case .app(let event):
            return event.savedPin?.placeName
        case .external(_, let location, _, _, _):
            return location
        }
    }

    var ekIdentifier: String? {
        switch self {
        case .app(let event):
            return event.eventKitEventID
        case .external(_, _, _, _, let ekIdentifier):
            return ekIdentifier
        }
    }

    var startDate: Date? {
        switch self {
        case .app(let event):
            return event.startDate
        case .external:
            return nil // We'd need to store this if needed for sorting
        }
    }
}

struct EventsTabView: View {
    @StateObject private var eventViewModel = EventViewModel()
    @StateObject private var eventKitService = EventKitService.shared
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showAddEvent = false
    @State private var searchText = ""
    @State private var allUpcomingEvents: [UpcomingEvent] = []
    @State private var isLoading = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EventEntity.startDate, ascending: true)],
        animation: .default
    )
    private var allEvents: FetchedResults<EventEntity>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EventEntity.startDate, ascending: true)],
        predicate: NSPredicate(format: "startDate > %@", Date() as NSDate),
        animation: .default
    )
    private var upcomingEvents: FetchedResults<EventEntity>

    private let calendar = Calendar.current
    private let dateFormatter = DateFormatters.monthYear

    private func getDatesWithEvents(for month: Date) -> Set<Date> {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let endOfMonth = calendar.dateInterval(of: .month, for: month)?.end ?? month

        let monthEvents = allEvents.filter { event in
            guard let startDate = event.startDate else { return false }
            return startDate >= startOfMonth && startDate <= endOfMonth
        }

        let dates = Set<Date>(monthEvents.compactMap { event in
            guard let startDate = event.startDate else { return nil }
            return calendar.startOfDay(for: startDate)
        })
        return dates
    }

    private var filteredEvents: [UpcomingEvent] {
        if searchText.isEmpty {
            return allUpcomingEvents
        } else {
            return allUpcomingEvents.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.location?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                CalendarView(
                    currentMonth: $currentMonth,
                    selectedDate: $selectedDate,
                    datesWithEvents: getDatesWithEvents(for: currentMonth),
                    eventViewModel: eventViewModel
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)

                UpcomingEventsSection(events: filteredEvents, eventViewModel: eventViewModel)
                    .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search events")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    showAddEvent = true
                }
                .foregroundColor(.blue)
            }
        }
        .fullScreenCover(isPresented: $showAddEvent) {
            AddEventView(eventViewModel: eventViewModel)
        }
        .onAppear {
            loadAllUpcomingEvents()
        }
        .onReceive(eventKitService.$shouldRefresh) { _ in
            loadAllUpcomingEvents()
        }
        .refreshable {
            eventViewModel.refreshEvents()
            loadAllUpcomingEvents()
        }
    }

    private func loadAllUpcomingEvents() {
        isLoading = true

        Task {
            var events: [UpcomingEvent] = []

            // Add Core Data events
            let coreDataEvents = Array(upcomingEvents)
            events.append(contentsOf: coreDataEvents.map { .app($0) })

            // Add EventKit events if access is granted
            if eventKitService.hasCalendarAccess {
                let now = Date()
                let futureDate = Calendar.current.date(byAdding: .month, value: 3, to: now) ?? now
                let ekEvents = eventKitService.fetchEvents(from: now, to: futureDate)

                let externalEvents = ekEvents.map { ekEvent -> UpcomingEvent in
                    let formattedDateTime = DateFormatters.eventDateTime.string(from: ekEvent.startDate)

                    return .external(
                        title: ekEvent.title ?? "Unknown Event",
                        location: ekEvent.location,
                        formattedTimeRange: formattedDateTime,
                        isAllDay: ekEvent.isAllDay,
                        ekIdentifier: ekEvent.eventIdentifier
                    )
                }
                events.append(contentsOf: externalEvents)
            }

            // Deduplicate events (prioritize app events over calendar events)
            let deduplicatedEvents = events.deduplicated()

            await MainActor.run {
                allUpcomingEvents = deduplicatedEvents
                isLoading = false
            }
        }
    }
}

struct CalendarView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let datesWithEvents: Set<Date>
    @ObservedObject var eventViewModel: EventViewModel
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatters.monthYear
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: currentMonth))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding(.horizontal, 8)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
                
                ForEach(daysInMonth(), id: \.self) { date in
                    NavigationLink(destination: DayEventsView(date: date, eventViewModel: eventViewModel)) {
                        CalendarDayViewContent(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            hasEvents: datesWithEvents.contains(calendar.startOfDay(for: date))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .simultaneousGesture(TapGesture().onEnded {
                        selectedDate = date
                    })
                }
            }
        }
    }
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func daysInMonth() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysToSubtract = firstWeekday - 1
        
        var days: [Date] = []
        let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstOfMonth)!
        
        for i in 0..<42 {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                days.append(date)
            }
        }
        
        return days
    }
}

struct CalendarDayViewContent: View {
    let date: Date
    let isSelected: Bool
    let hasEvents: Bool

    private let calendar = Calendar.current

    var isCurrentMonth: Bool {
        calendar.isDate(date, equalTo: Date(), toGranularity: .month)
    }

    var isToday: Bool {
        calendar.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor)

            if hasEvents {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 4, height: 4)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(width: 32, height: 36)
        .background(
            Circle()
                .fill(backgroundColor)
                .frame(width: 32, height: 32)
        )
        .contentShape(Rectangle())
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .blue
        } else if !isCurrentMonth {
            return .secondary
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .blue.opacity(0.1)
        } else {
            return .clear
        }
    }
}

struct UpcomingEventsSection: View {
    let events: [UpcomingEvent]
    @ObservedObject var eventViewModel: EventViewModel
    @State private var eventToDelete: EventEntity?
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upcoming events")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)
            
            if events.isEmpty {
                Text("No upcoming events")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            } else {
                TimelineView(.periodic(from: .now, by: 5.0)) { context in
                    LazyVStack(spacing: 12) {
                        ForEach(events, id: \.id) { upcomingEvent in
                            switch upcomingEvent {
                            case .app(let event):
                                EventCard(event: event, currentTime: context.date) {
                                    eventToDelete = event
                                    showDeleteConfirmation = true
                                }
                            case .external(let title, let location, let formattedTimeRange, let isAllDay, _):
                                EventCardExternal(
                                    title: title,
                                    location: location,
                                    formattedTimeRange: formattedTimeRange,
                                    isAllDay: isAllDay
                                )
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .alert("Delete Event", isPresented: $showDeleteConfirmation, presenting: eventToDelete) { event in
            Button("Delete", role: .destructive) {
                Task {
                    await eventViewModel.deleteEvent(event)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: { event in
            Text("Are you sure you want to delete '\(event.name ?? "this event")'? This action cannot be undone.")
        }
    }
}


// MARK: - Deduplication Logic
extension Array where Element == UpcomingEvent {
    // Remove duplicates, prioritizing app events over calendar events
    func deduplicated() -> [UpcomingEvent] {
        var seen = Set<String>()
        var result: [UpcomingEvent] = []

        // First pass: add all app events
        for event in self {
            if case .app(_) = event {
                if let ekIdentifier = event.ekIdentifier {
                    seen.insert(ekIdentifier)
                }
                result.append(event)
            }
        }

        // Second pass: add external events that don't have matching app events
        for event in self {
            if case .external(_, _, _, _, _) = event {
                if let ekIdentifier = event.ekIdentifier, !seen.contains(ekIdentifier) {
                    result.append(event)
                }
            }
        }

        // Sort by start date where available, then by title
        return result.sorted { event1, event2 in
            if let date1 = event1.startDate, let date2 = event2.startDate {
                return date1 < date2
            }
            return event1.title < event2.title
        }
    }
}

#Preview {
    EventsTabView()
}
