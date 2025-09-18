//
//  MapTabView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-17.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - POI Category Helper

struct POICategoryInfo {
    let icon: String
    let color: Color
}

func getPOICategoryInfo(for category: String?) -> POICategoryInfo {
    guard let category = category else {
        return POICategoryInfo(icon: "building.2.fill", color: .blue)
    }

    switch category {
    case "MKPOICategoryRestaurant":
        return POICategoryInfo(icon: "fork.knife", color: .red)
    case "MKPOICategoryGasStation":
        return POICategoryInfo(icon: "fuelpump.fill", color: .blue)
    case "MKPOICategoryHospital":
        return POICategoryInfo(icon: "cross.fill", color: .red)
    case "MKPOICategoryPharmacy":
        return POICategoryInfo(icon: "cross.case.fill", color: .green)
    case "MKPOICategoryBank":
        return POICategoryInfo(icon: "dollarsign.circle.fill", color: .green)
    case "MKPOICategoryATM":
        return POICategoryInfo(icon: "creditcard.fill", color: .blue)
    case "MKPOICategoryHotel":
        return POICategoryInfo(icon: "bed.double.fill", color: .purple)
    case "MKPOICategorySchool":
        return POICategoryInfo(icon: "graduationcap.fill", color: .blue)
    case "MKPOICategoryLibrary":
        return POICategoryInfo(icon: "book.fill", color: .brown)
    case "MKPOICategoryMuseum":
        return POICategoryInfo(icon: "building.columns.fill", color: .purple)
    case "MKPOICategoryMovieTheater":
        return POICategoryInfo(icon: "tv.fill", color: .indigo)
    case "MKPOICategoryNightlife":
        return POICategoryInfo(icon: "wineglass.fill", color: .purple)
    case "MKPOICategoryPark":
        return POICategoryInfo(icon: "tree.fill", color: .green)
    case "MKPOICategoryAmusementPark":
        return POICategoryInfo(icon: "gamecontroller.fill", color: .pink)
    case "MKPOICategoryAquarium":
        return POICategoryInfo(icon: "fish.fill", color: .blue)
    case "MKPOICategoryZoo":
        return POICategoryInfo(icon: "pawprint.fill", color: .blue)
    case "MKPOICategoryStadium":
        return POICategoryInfo(icon: "sportscourt.fill", color: .blue)
    case "MKPOICategoryLaundry":
        return POICategoryInfo(icon: "washer.fill", color: .blue)
    case "MKPOICategoryFoodMarket":
        return POICategoryInfo(icon: "cart.fill", color: .green)
    case "MKPOICategoryBakery":
        return POICategoryInfo(icon: "birthday.cake.fill", color: .blue)
    case "MKPOICategoryCafe":
        return POICategoryInfo(icon: "cup.and.saucer.fill", color: .brown)
    case "MKPOICategoryStore":
        return POICategoryInfo(icon: "bag.fill", color: .blue)
    case "MKPOICategoryParking":
        return POICategoryInfo(icon: "car.fill", color: .gray)
    case "MKPOICategoryPostOffice":
        return POICategoryInfo(icon: "envelope.fill", color: .blue)
    case "MKPOICategoryPublicTransport":
        return POICategoryInfo(icon: "bus.fill", color: .blue)
    case "MKPOICategoryAirport":
        return POICategoryInfo(icon: "airplane", color: .blue)
    case "MKPOICategoryBeach":
        return POICategoryInfo(icon: "beach.umbrella.fill", color: .cyan)
    case "MKPOICategoryMarina":
        return POICategoryInfo(icon: "sailboat.fill", color: .blue)
    case "MKPOICategoryEVCharger":
        return POICategoryInfo(icon: "bolt.fill", color: .green)
    default:
        return POICategoryInfo(icon: "building.2.fill", color: .blue)
    }
}

struct MapTabView: View {
    @StateObject private var viewModel = MapViewModel()
    @StateObject private var searchViewModel = MapSearchViewModel()
    @StateObject private var navigationViewModel = NavigationViewModel()
    @EnvironmentObject var router: AppRouter
    @Environment(\.managedObjectContext) private var context
    
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
                                    viewModel.selectSavedPin(annotation)
                                    router.mapDeepLink = .showPinDetails(annotation.savedPin.objectID)
                                }
                            )
                        }
                    }
                    
                    // Navigation Route
                    if let route = navigationViewModel.currentRoute {
                        MapPolyline(route.polyline)
                            .stroke(.blue, lineWidth: 5)
                    }
                }
                .mapControlVisibility(.hidden)
                .onMapCameraChange(frequency: .continuous) { context in
                    viewModel.updateCurrentMapRegion(context.region)
                }
                .onTapGesture { location in
                    if searchViewModel.isSearchActive {
                        searchViewModel.searchText = ""
                        return
                    }
                    
                    if let coordinate = proxy.convert(location, from: .local) {
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
                    .padding(.bottom, navigationViewModel.isNavigating ? 24 : 16)
                }
                
                if navigationViewModel.isNavigating {
                    NavigationInfoPanel(
                        navigationViewModel: navigationViewModel,
                        userLocation: viewModel.userLocation
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24) // Slightly above legal label
                }
            }
            
            if searchViewModel.isSearchActive {
                VStack {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if !searchViewModel.savedPinResults.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Your pins")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 16)
                                    
                                    ForEach(searchViewModel.savedPinResults) { result in
                                        Button(action: {
                                            let annotation = SavedPinAnnotation(savedPin: result.savedPin)
                                            viewModel.selectSavedPin(annotation)
                                            router.mapDeepLink = .showPinDetails(result.savedPin.objectID)
                                            searchViewModel.searchText = ""
                                        }) {
                                            HStack(spacing: 12) {
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
                                        Button(action: {
                                            viewModel.selectSearchPlace(result)
                                            searchViewModel.searchText = ""
                                        }) {
                                            HStack(spacing: 12) {
                                                VStack(spacing: 4) {
                                                    let categoryInfo = getPOICategoryInfo(for: result.category)
                                                    Circle()
                                                        .fill(categoryInfo.color.opacity(0.2))
                                                        .frame(width: 32, height: 32)
                                                        .overlay(
                                                            Image(systemName: categoryInfo.icon)
                                                                .font(.system(size: 14))
                                                                .foregroundColor(categoryInfo.color)
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
        .onChange(of: router.shouldStartNavigation) { _, triggerObjectID in
            guard let triggerObjectID = triggerObjectID,
                  let userLocation = viewModel.userLocation else { return }

            // Find the savedPin with the matching objectID
            if let savedPin = try? context.existingObject(with: triggerObjectID) as? SavedPinEntity {
                navigationViewModel.startNavigation(to: savedPin, from: userLocation)
            }

            router.clearNavigationTrigger()
        }
    }
}



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


struct NavigationInfoPanel: View {
    @ObservedObject var navigationViewModel: NavigationViewModel
    var userLocation: CLLocationCoordinate2D?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Transport mode and destination info
                VStack(alignment: .leading, spacing: 4) {
                    if let destinationPin = navigationViewModel.destinationPin {
                        HStack(spacing: 0) {
                            Text("To ")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(destinationPin.placeName)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        .lineLimit(1)
                    }
                    
                    HStack(spacing: 4) {
                        Text(navigationViewModel.formattedDistance)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("•")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(navigationViewModel.formattedETA)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                // Cancel button
                Button(action: {
                    navigationViewModel.cancelNavigation()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 24))
                }
            }
            
            // Transport mode selection
            HStack(spacing: 12) {
                TransportModeButton(
                    icon: "car.fill",
                    type: .automobile,
                    isSelected: navigationViewModel.transportType == .automobile,
                    navigationViewModel: navigationViewModel,
                    userLocation: userLocation
                )
                
                TransportModeButton(
                    icon: "figure.walk",
                    type: .walking,
                    isSelected: navigationViewModel.transportType == .walking,
                    navigationViewModel: navigationViewModel,
                    userLocation: userLocation
                )
                
                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct TransportModeButton: View {
    let icon: String
    let type: MKDirectionsTransportType
    let isSelected: Bool
    @ObservedObject var navigationViewModel: NavigationViewModel
    var userLocation: CLLocationCoordinate2D?
    
    var body: some View {
        Button(action: {
            if let userLocation = userLocation {
                navigationViewModel.changeTransportType(type, userLocation: userLocation)
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : .blue)
                .frame(width: 44, height: 44)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                .clipShape(Circle())
        }
    }
}


#Preview {
    MapTabView()
        .environmentObject(AppRouter())
}
