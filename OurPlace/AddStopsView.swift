//
//  AddStopsView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-15.
//

import SwiftUI

struct AddStopsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var savesViewModel = SavesTabViewModel()
    @State private var searchText = ""
    
    let onStopSelected: (SavedPinEntity) -> Void
    
    private var filteredPins: [SavedPinEntity] {
        if searchText.isEmpty {
            return savesViewModel.savedPins
        } else {
            return savesViewModel.savedPins.filter { pin in
                pin.placeName.localizedCaseInsensitiveContains(searchText) ||
                pin.address.localizedCaseInsensitiveContains(searchText) ||
                pin.category?.name.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Add Button
                HStack {
                    Spacer()
                    Button("Add") {
                        // This button seems to be in the design but not clear what it does
                        // Maybe for adding a new pin directly from here
                    }
                    .foregroundColor(.blue)
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }
                
                // Pins List
                if filteredPins.isEmpty {
                    EmptyAddStopsView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredPins, id: \.id) { pin in
                                AddStopRowView(
                                    pin: pin,
                                    onTap: {
                                        onStopSelected(pin)
                                        dismiss()
                                    }
                                )
                                
                                if pin.id != filteredPins.last?.id {
                                    Divider()
                                        .padding(.leading, 76)
                                }
                            }
                        }
                        .padding(.top, 16)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Add Stop")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            savesViewModel.loadSavedPins()
        }
    }
}

// MARK: - Add Stop Row View
struct AddStopRowView: View {
    let pin: SavedPinEntity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category icon
                if let category = pin.category {
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
                
                // Pin details
                VStack(alignment: .leading, spacing: 4) {
                    Text(pin.placeName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(pin.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Category tag if exists
                    if let category = pin.category {
                        HStack {
                            Text(category.displayText)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(category.color)
                                .cornerRadius(4)
                            
                            Spacer()
                            
                            // Date from the design
                            Text("20.06.2025") // TODO: Use actual date from pin
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty Add Stops View
struct EmptyAddStopsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "mappin.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Saved Pins")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Save some pins first to add them as route stops")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    AddStopsView { pin in
        print("Selected pin: \(pin.placeName)")
    }
}