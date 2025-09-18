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
        VStack {
            // Pins List
            if filteredPins.isEmpty {
                EmptyAddStopsView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredPins, id: \.id) { pin in
                            SavedPinCard(
                                pin: pin,
                                action: {
                                    onStopSelected(pin)
                                    dismiss()
                                },
                                showDate: false
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Add Stop")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            savesViewModel.loadSavedPins()
        }
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