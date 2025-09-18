//
//  EventsTabView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-21.
//

import SwiftUI
import CoreData

struct EventsTabView: View {
    @StateObject private var eventViewModel = EventViewModel()
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showAddEvent = false

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
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

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

    var body: some View {
        VStack(spacing: 0) {
            CalendarView(
                currentMonth: $currentMonth,
                selectedDate: $selectedDate,
                datesWithEvents: getDatesWithEvents(for: currentMonth),
                eventViewModel: eventViewModel
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)

            UpcomingEventsSection(events: Array(upcomingEvents), eventViewModel: eventViewModel)
                .padding(.horizontal, 16)
        }
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showAddEvent = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.blue)
                }
            }
        }
        .fullScreenCover(isPresented: $showAddEvent) {
            AddEventView(eventViewModel: eventViewModel)
        }
        .refreshable {
            eventViewModel.refreshEvents()
        }
    }
}

struct CalendarView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let datesWithEvents: Set<Date>
    @ObservedObject var eventViewModel: EventViewModel
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
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
    let events: [EventEntity]
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
                        ForEach(events, id: \.id) { event in
                            EventRowView(event: event, currentTime: context.date)
                                .contextMenu {
                                    Button("Delete Event", systemImage: "trash", role: .destructive) {
                                        eventToDelete = event
                                        showDeleteConfirmation = true
                                    }
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

struct EventRowView: View {
    let event: EventEntity
    let currentTime: Date
    
    var body: some View {
        HStack(spacing: 12) {
            if let category = event.savedPin?.category {
                Circle()
                    .fill(category.color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(category.symbol)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    )
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name ?? "Unknown Event")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("At \(event.savedPin?.placeName ?? "Unknown Location")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(event.formattedDateTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(timeUntilEvent(for: event, from: currentTime))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func timeUntilEvent(for event: EventEntity, from currentTime: Date) -> String {
        guard let startDate = event.startDate else {
            return "Unknown time"
        }

        let timeInterval = startDate.timeIntervalSince(currentTime)
        
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
}

#Preview {
    EventsTabView()
}
