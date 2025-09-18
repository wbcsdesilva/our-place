//
//  AddEventView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-21.
//

import SwiftUI
import CoreData

struct AddEventView: View {
    @ObservedObject var eventViewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var savesViewModel = SavesTabViewModel()
    
    @State private var eventName = ""
    @State private var selectedPin: SavedPinEntity?
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // 1 hour later
    @State private var isAllDay = false
    @State private var reminderMinutes: Int16 = 15
    @State private var allDayReminderDays: Int = 0
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let reminderOptions: [Int16] = [5, 10, 15, 30, 60]
    private let allDayReminderOptions = [
        (0, "On day of event (9:00 AM)"),
        (1, "1 day before (9:00 AM)"),
        (2, "2 days before (9:00 AM)"),
        (7, "1 week before (9:00 AM)")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Event name", text: $eventName)
                        .textFieldStyle(.plain)
                        .accessibilityLabel("Event name")
                        .accessibilityHint("Enter the name for your event")
                }
                
                Section("Location") {
                    if savesViewModel.savedPins.isEmpty {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("No saved pins available. Save some locations first.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        Picker("Select Pin", selection: $selectedPin) {
                            Text("Choose a location")
                                .tag(nil as SavedPinEntity?)

                            ForEach(savesViewModel.savedPins, id: \.id) { pin in
                                HStack {
                                    if let category = pin.category {
                                        Circle()
                                            .fill(category.color)
                                            .frame(width: 20, height: 20)
                                            .overlay(
                                                Text(category.symbol)
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white)
                                            )
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(pin.placeName)
                                            .font(.body)
                                        Text(pin.shortAddress)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tag(pin as SavedPinEntity?)
                            }
                        }
                        .pickerStyle(.navigationLink)
                        .accessibilityLabel("Event location")
                        .accessibilityValue(selectedPin?.placeName ?? "No location selected")
                        .accessibilityHint("Choose a saved location for your event")
                    }
                }
                
                Section("Date & Time") {
                    Toggle("All Day", isOn: $isAllDay)
                        .accessibilityLabel("All day event")
                        .accessibilityHint("Toggle to make this an all-day event")
                        .onChange(of: isAllDay) { _, newValue in
                            if newValue {
                                // Set to start of day for all-day events
                                let calendar = Calendar.current
                                startDate = calendar.startOfDay(for: startDate)
                                endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? startDate
                            } else {
                                // Set to current time + 1 hour for timed events
                                startDate = Date()
                                endDate = startDate.addingTimeInterval(3600)
                            }
                        }

                    if isAllDay {
                        DatePicker("Date", selection: $startDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .accessibilityLabel("Event date")
                            .accessibilityHint("Select the date for your all-day event")
                            .onChange(of: startDate) { _, newStartDate in
                                let calendar = Calendar.current
                                startDate = calendar.startOfDay(for: newStartDate)
                                endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? startDate
                            }
                    } else {
                        DatePicker("Start", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .accessibilityLabel("Event start time")
                            .accessibilityHint("Select when your event starts")
                            .onChange(of: startDate) { _, newStartDate in
                                // Ensure end date is always after start date
                                if endDate <= newStartDate {
                                    endDate = newStartDate.addingTimeInterval(3600) // 1 hour later
                                }
                            }

                        DatePicker("End", selection: $endDate, in: startDate.addingTimeInterval(60)..., displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .accessibilityLabel("Event end time")
                            .accessibilityHint("Select when your event ends")
                    }
                }
                
                Section("Reminder") {
                    if isAllDay {
                        Picker("Remind me", selection: $allDayReminderDays) {
                            ForEach(allDayReminderOptions, id: \.0) { option in
                                Text(option.1)
                                    .tag(option.0)
                            }
                        }
                        .pickerStyle(.navigationLink)
                        .accessibilityLabel("Reminder timing")
                        .accessibilityValue(allDayReminderOptions.first { $0.0 == allDayReminderDays }?.1 ?? "")
                        .accessibilityHint("Choose when to be reminded about your all-day event")
                    } else {
                        Picker("Remind me before", selection: $reminderMinutes) {
                            ForEach(reminderOptions, id: \.self) { minutes in
                                if minutes < 60 {
                                    Text("\(minutes) minutes")
                                        .tag(minutes)
                                } else {
                                    Text("\(minutes / 60) hour\(minutes == 60 ? "" : "s")")
                                        .tag(minutes)
                                }
                            }
                        }
                        .pickerStyle(.navigationLink)
                        .accessibilityLabel("Reminder timing")
                        .accessibilityValue("\(reminderMinutes) minutes before")
                        .accessibilityHint("Choose how many minutes before the event to be reminded")
                    }
                }
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Discard event and return to previous screen")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEvent()
                    }
                    .disabled(isLoading || !isFormValid)
                    .accessibilityLabel("Save event")
                    .accessibilityHint(isFormValid ? "Create the event with current settings" : "Fill in all required fields to save")
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView("Creating event...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Creating event")
                        .accessibilityHint("Please wait while your event is being created")
                }
            }
        }
        .onAppear {
            savesViewModel.loadSavedPins()
        }
    }
    
    private var isFormValid: Bool {
        !eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedPin != nil &&
        startDate > Date() &&
        endDate > startDate
    }

    private func calculateReminderMinutesForAllDay() -> Int16 {
        // For all-day events, calculate minutes from 9 AM on the reminder day to event start
        let calendar = Calendar.current
        let eventStartDay = calendar.startOfDay(for: startDate)
        let reminderDay = calendar.date(byAdding: .day, value: -allDayReminderDays, to: eventStartDay) ?? eventStartDay
        let reminderTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: reminderDay) ?? reminderDay

        let interval = startDate.timeIntervalSince(reminderTime)
        return Int16(interval / 60) // Convert seconds to minutes
    }
    
    private func saveEvent() {
        guard let selectedPin = selectedPin else {
            errorMessage = "Please select a location for the event"
            showError = true
            return
        }
        
        guard isFormValid else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            let finalReminderMinutes = isAllDay ? calculateReminderMinutesForAllDay() : reminderMinutes

            let success = await eventViewModel.createEvent(
                name: eventName.trimmingCharacters(in: .whitespacesAndNewlines),
                startDate: startDate,
                endDate: endDate,
                reminderMinutes: finalReminderMinutes,
                isAllDay: isAllDay,
                savedPin: selectedPin
            )
            
            await MainActor.run {
                isLoading = false
                
                if success {
                    dismiss()
                } else {
                    errorMessage = eventViewModel.errorMessage ?? "Failed to create event"
                    showError = true
                }
            }
        }
    }
}

struct PinSelectionRow: View {
    let pin: SavedPinEntity
    
    var body: some View {
        HStack(spacing: 12) {
            if let category = pin.category {
                Circle()
                    .fill(category.color)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(category.symbol)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pin.placeName)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(pin.shortAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
    }
}

#Preview {
    AddEventView(eventViewModel: EventViewModel())
}