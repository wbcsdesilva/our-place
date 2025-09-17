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
    @State private var selectedDate = Date()
    @State private var reminderMinutes: Int16 = 15
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let reminderOptions: [Int16] = [5, 10, 15, 30, 60]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Event name", text: $eventName)
                        .textFieldStyle(.plain)
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
                    }
                }
                
                Section("Date & Time") {
                    DatePicker("Event Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }
                
                Section("Reminder") {
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
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEvent()
                    }
                    .disabled(isLoading || !isFormValid)
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
        selectedDate > Date()
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
            let success = await eventViewModel.createEvent(
                name: eventName.trimmingCharacters(in: .whitespacesAndNewlines),
                eventDate: selectedDate,
                reminderMinutes: reminderMinutes,
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