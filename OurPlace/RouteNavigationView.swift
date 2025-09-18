//
//  RouteNavigationView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-16.
//

import SwiftUI
import MapKit
import CoreLocation

struct RouteNavigationView: View {
    let route: RouteEntity
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: RouteNavigationViewModel

    @State private var mapPosition = MapCameraPosition.automatic

    init(route: RouteEntity) {
        self.route = route
        self._viewModel = StateObject(wrappedValue: RouteNavigationViewModel(route: route))
    }

    var body: some View {
        ZStack {
            // Full screen map
            MapReader { proxy in
                Map(position: $mapPosition) {
                    // User location
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

                    // Route stops
                    ForEach(Array(viewModel.routeStops.enumerated()), id: \.element.id) { index, stop in
                        if let savedPin = stop.savedPin {
                            Annotation("", coordinate: CLLocationCoordinate2D(latitude: savedPin.latitude, longitude: savedPin.longitude)) {
                                ZStack {
                                    // Pin visual
                                    if let category = savedPin.category {
                                        Circle()
                                            .fill(category.color)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Text(category.symbol)
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.white)
                                            )
                                            .shadow(radius: 4)
                                    } else {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 35))
                                            .shadow(radius: 3)
                                    }

                                    // Stop number indicator
                                    VStack {
                                        Text("\(index + 1)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .frame(width: 18, height: 18)
                                            .background(Circle().fill(viewModel.currentStopIndex == index ? Color.green : Color.blue))

                                        Spacer()
                                    }
                                    .offset(x: -15, y: -15)

                                    // Current destination indicator
                                    if viewModel.currentStopIndex == index {
                                        Circle()
                                            .stroke(Color.green, lineWidth: 3)
                                            .frame(width: 50, height: 50)
                                            .scaleEffect(1.0)
                                            .opacity(0.8)
                                    }
                                }
                            }
                        }
                    }

                    // Full route polylines with current segment highlighting
                    ForEach(Array(viewModel.allRouteSegments.enumerated()), id: \.offset) { index, routeSegment in
                        MapPolyline(routeSegment.polyline)
                            .stroke(
                                index == viewModel.currentSegmentIndex ? Color.blue : Color.blue.opacity(0.4),
                                style: StrokeStyle(
                                    lineWidth: index == viewModel.currentSegmentIndex ? 8 : 4,
                                    lineCap: .round,
                                    lineJoin: .round
                                )
                            )
                    }
                }
                .mapControlVisibility(.hidden)
                .onMapCameraChange(frequency: .continuous) { context in
                    // Update map position if needed
                }
            }


            // Navigation control panel (bottom)
            VStack {
                Spacer()

                RouteNavigationControlPanel(viewModel: viewModel, onDismiss: {
                    dismiss()
                })
                    .padding(.horizontal, 16)
                    .padding(.bottom, 34) // Account for safe area
            }
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.startNavigation()
            centerMapOnRoute()
        }
        .onChange(of: viewModel.currentStopIndex) { _, _ in
            centerMapOnCurrentStop()
        }
        .onChange(of: viewModel.allRouteSegments) { _, _ in
            if !viewModel.allRouteSegments.isEmpty {
                centerMapOnRoute()
            }
        }
    }

    private func centerMapOnRoute() {
        guard !viewModel.routeStops.isEmpty else { return }

        let coordinates = viewModel.routeStops.compactMap { stop -> CLLocationCoordinate2D? in
            guard let savedPin = stop.savedPin else { return nil }
            return CLLocationCoordinate2D(latitude: savedPin.latitude, longitude: savedPin.longitude)
        }

        guard !coordinates.isEmpty else { return }

        // Add user location if available
        var allCoordinates = coordinates
        if let userLocation = viewModel.userLocation {
            allCoordinates.append(userLocation)
        }

        let minLat = allCoordinates.map { $0.latitude }.min() ?? 0
        let maxLat = allCoordinates.map { $0.latitude }.max() ?? 0
        let minLon = allCoordinates.map { $0.longitude }.min() ?? 0
        let maxLon = allCoordinates.map { $0.longitude }.max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.01) * 1.5,
            longitudeDelta: max(maxLon - minLon, 0.01) * 1.5
        )

        mapPosition = .region(MKCoordinateRegion(center: center, span: span))
    }

    private func centerMapOnCurrentStop() {
        guard let currentDestination = viewModel.currentDestination else { return }

        let center = CLLocationCoordinate2D(
            latitude: currentDestination.latitude,
            longitude: currentDestination.longitude
        )

        mapPosition = .region(MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
}

// MARK: - Navigation Control Panel

struct RouteNavigationControlPanel: View {
    @ObservedObject var viewModel: RouteNavigationViewModel
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header row with destination and dismiss button
            HStack {
                if let destination = viewModel.currentDestination {
                    Text("To \(destination.placeName)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Spacer()

                // Smaller dismiss button
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.gray)
                }
            }

            // Progress info section
            VStack(alignment: .leading, spacing: 8) {
                // Current segment info
                HStack(spacing: 8) {
                    Text(viewModel.progressText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(viewModel.formattedCurrentDistance)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(viewModel.formattedCurrentETA)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                // Total route info
                HStack(spacing: 8) {
                    Text("Total route:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(viewModel.formattedTotalRouteDistance)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(viewModel.formattedTotalRouteETA)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(viewModel.formattedTotalDistance) remaining")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }


            // Transport mode and status section
            HStack(spacing: 16) {
                // Transport mode buttons
                HStack(spacing: 12) {
                    RouteTransportModeButton(
                        icon: "car.fill",
                        type: .automobile,
                        isSelected: viewModel.transportType == .automobile,
                        action: { viewModel.changeTransportType(.automobile) }
                    )

                    RouteTransportModeButton(
                        icon: "figure.walk",
                        type: .walking,
                        isSelected: viewModel.transportType == .walking,
                        action: { viewModel.changeTransportType(.walking) }
                    )
                }

                Spacer()

                // Status indicators
                VStack(alignment: .trailing, spacing: 4) {
                    // Error display
                    if let error = viewModel.routeError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .lineLimit(2)
                    }

                    // Loading indicator
                    if viewModel.isCalculatingRoute || viewModel.isCalculatingFullRoute {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text(viewModel.isCalculatingFullRoute ? "Calculating..." : "Updating...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Transport Mode Button

struct RouteTransportModeButton: View {
    let icon: String
    let type: MKDirectionsTransportType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isSelected ? .white : .blue)
                .frame(width: 50, height: 50)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                .clipShape(Circle())
        }
    }
}

#Preview {
    let context = CoreDataService.shared.context
    let sampleRoute = RouteEntity(context: context, name: "Sample Route")

    RouteNavigationView(route: sampleRoute)
}