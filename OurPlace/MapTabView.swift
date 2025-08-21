//
//  MapTabView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-17.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapTabView: View {
    @StateObject private var viewModel = MapViewModel()
    @StateObject private var searchViewModel = MapSearchViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
            MapReader { proxy in
                Map(position: $viewModel.cameraPosition) {
                    if let userLocation = viewModel.userLocation {
                        Annotation("My Location", coordinate: userLocation) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .shadow(radius: 3)
                        }
                    }
                    
                    if let pin = viewModel.droppedPin {
                        Annotation("Dropped Pin", coordinate: pin.coordinate, anchor: .bottom) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.red)
                                .font(.system(size: 30))
                                .shadow(radius: 3)
                        }
                    }
                    
                    // Saved Pins
                    ForEach(viewModel.savedPinAnnotations, id: \.savedPin.id) { annotation in
                        Annotation(
                            "",
                            coordinate: annotation.coordinate,
                            anchor: .center
                        ) {
                            SavedPinAnnotationView(
                                annotation: annotation,
                                onTap: { annotation in
                                    viewModel.showSavedPinDetails(annotation)
                                }
                            )
                        }
                    }
                }
                .mapControlVisibility(.hidden)
                .onMapCameraChange(frequency: .continuous) { context in
                    viewModel.updateCurrentMapRegion(context.region)
                }
                .onTapGesture { location in
                    print("Map tapped at location: \\(location)") // Debug log
                    
                    // Dismiss search if active
                    if searchViewModel.isSearchActive {
                        searchViewModel.searchText = ""
                        return
                    }
                    
                    // Otherwise drop pin
                    if let coordinate = proxy.convert(location, from: .local) {
                        print("Dropping pin at coordinate: \\(coordinate)") // Debug log
                        viewModel.dropPinAtCoordinate(coordinate)
                    }
                }
            }
            
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        viewModel.centerOnUserLocation()
                    }) {
                        Image(systemName: "rotate.3d.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                            .frame(width: 56, height: 56)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
            }
            
            // Search Results Overlay
            if searchViewModel.isSearchActive {
                VStack {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Your Pins Section
                            if !searchViewModel.savedPinResults.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Your pins")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 16)
                                    
                                    ForEach(searchViewModel.savedPinResults) { result in
                                        Button(action: {
                                            let annotation = SavedPinAnnotation(savedPin: result.savedPin)
                                            viewModel.showSavedPinDetails(annotation)
                                            searchViewModel.searchText = ""
                                        }) {
                                            HStack(spacing: 12) {
                                                // Category color circle with emoji
                                                if let category = result.savedPin.category {
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
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(result.savedPin.placeName)
                                                        .font(.body)
                                                        .foregroundColor(.primary)
                                                    
                                                    if !result.savedPin.shortAddress.isEmpty {
                                                        Text(result.savedPin.shortAddress)
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                            .lineLimit(1)
                                                    }
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(12)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(12)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal, 16)
                                    }
                                }
                            }
                            
                            // Places Section
                            if searchViewModel.isLoadingPOIs {
                                HStack {
                                    ProgressView()
                                    Text("Searching places...")
                                    Spacer()
                                }
                                .padding()
                            } else if !searchViewModel.poiResults.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Places")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 16)
                                    
                                    ForEach(searchViewModel.poiResults) { result in
                                        HStack(spacing: 12) {
                                            // POI icon with distance below
                                            VStack(spacing: 4) {
                                                Circle()
                                                    .fill(Color.orange.opacity(0.2))
                                                    .frame(width: 32, height: 32)
                                                    .overlay(
                                                        Image(systemName: "building.2.fill")
                                                            .font(.system(size: 14))
                                                            .foregroundColor(.orange)
                                                    )
                                                
                                                if let distance = result.distance {
                                                    Text(distance < 1000 ? String(format: "%.0fm", distance) : String(format: "%.1fkm", distance / 1000))
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(result.name)
                                                    .font(.body)
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                                
                                                Text(result.address)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(2)
                                            }
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                viewModel.selectSearchPlace(result)
                                                searchViewModel.searchText = ""
                                            }) {
                                                Image(systemName: "mappin")
                                                    .foregroundColor(.blue)
                                                    .font(.system(size: 16))
                                                    .frame(width: 32, height: 32)
                                                    .background(Color.blue.opacity(0.1))
                                                    .clipShape(Circle())
                                            }
                                        }
                                        .padding(12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                        .padding(.horizontal, 16)
                                    }
                                }
                            }
                            
                            if !searchViewModel.hasResults && !searchViewModel.isLoadingPOIs && !searchViewModel.searchText.isEmpty {
                                Text("No results found")
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .shadow(radius: 8)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .frame(maxHeight: 300)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.2), value: searchViewModel.isSearchActive)
            }
        }
        .searchable(text: $searchViewModel.searchText, prompt: "Search places or your pins")
        .onChange(of: searchViewModel.searchText) { _, newValue in
            searchViewModel.updateSearchText(newValue)
        }
        .sheet(isPresented: $viewModel.showPinDetails) {
            PinDetailsSheet(
                pin: viewModel.droppedPin,
                address: viewModel.reverseGeocodedAddress,
                nearbyPlaces: viewModel.nearbyPlaces,
                isLoading: viewModel.isLoadingNearbyPlaces,
                onSnapToPlace: viewModel.snapPinToPlace,
                onSaveAsIs: viewModel.savePinAsIs,
                onDismiss: viewModel.dismissPinDetails
            )
            .presentationDetents([.height(400)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $viewModel.showSavePinView) {
            if let pin = viewModel.droppedPin {
                SavePinView(
                    pin: pin,
                    placeName: viewModel.getPinPlaceName(),
                    address: viewModel.reverseGeocodedAddress,
                    onSaveSuccess: viewModel.onPinSavedSuccessfully,
                    onCancel: viewModel.onSavePinCancelled
                )
            }
        }
        .fullScreenCover(isPresented: $viewModel.showPinDetailsView) {
            if let savedPin = viewModel.selectedSavedPin {
                PinDetailsView(savedPin: savedPin)
            }
        }
        .onAppear {
            viewModel.refreshSavedPins()
            if let userLocation = viewModel.userLocation {
                searchViewModel.setUserLocation(userLocation)
            }
        }
        .onChange(of: viewModel.userLocation) { _, newLocation in
            if let location = newLocation {
                searchViewModel.setUserLocation(location)
            }
        }
        }
    }
}


// MARK: - Pin Details Sheet

struct PinDetailsSheet: View {
    let pin: DroppedPin?
    let address: String
    let nearbyPlaces: [NearbyPlace]
    let isLoading: Bool
    let onSnapToPlace: (NearbyPlace) -> Void
    let onSaveAsIs: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            PinDetailsHeader(
                pin: pin,
                address: address,
                onDismiss: onDismiss
            )
            
            NearbyPlacesSection(
                nearbyPlaces: nearbyPlaces,
                isLoading: isLoading,
                onSnapToPlace: onSnapToPlace
            )
            
            Spacer()
            
            SavePinButton(action: onSaveAsIs)
        }
    }
}

// MARK: - Pin Details Components

struct PinDetailsHeader: View {
    let pin: DroppedPin?
    let address: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(address.isEmpty ? "Loading address..." : address)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let pin = pin {
                    Text("\(pin.coordinate.latitude, specifier: "%.4f"), \(pin.coordinate.longitude, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Cancel", action: onDismiss)
                .foregroundColor(.blue)
        }
        .padding()
    }
}

struct NearbyPlacesSection: View {
    let nearbyPlaces: [NearbyPlace]
    let isLoading: Bool
    let onSnapToPlace: (NearbyPlace) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nearby places you may have meant")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Finding nearby places...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if nearbyPlaces.isEmpty {
                Text("No nearby places found")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(nearbyPlaces) { place in
                            NearbyPlaceRow(place: place) {
                                onSnapToPlace(place)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding(.horizontal)
    }
}

struct SavePinButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Save pin as is")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
        }
        .padding()
    }
}

struct NearbyPlaceRow: View {
    let place: NearbyPlace
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(place.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text("\(place.coordinate.latitude, specifier: "%.4f"), \(place.coordinate.longitude, specifier: "%.4f")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onTap) {
                Image(systemName: "link")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                    .frame(width: 32, height: 32)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}


#Preview {
    MapTabView()
}
