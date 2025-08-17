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
    
    var body: some View {
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
                }
                .mapControlVisibility(.hidden)
                .onMapCameraChange(frequency: .continuous) { context in
                    viewModel.updateCurrentMapRegion(context.region)
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    if let coordinate = proxy.convert(location, from: .local) {
                        viewModel.dropPinAtCoordinate(coordinate)
                    }
                }
            }
            
            VStack {
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search", text: $viewModel.searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
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
