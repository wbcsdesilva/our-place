//
//  RouteDetailsView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-15.
//

import SwiftUI
import MapKit
import CoreLocation

struct RouteDetailsView: View {
    let route: RouteEntity
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: RouteDetailsViewModel
    @State private var showEditView = false
    @State private var showNavigationView = false

    init(route: RouteEntity) {
        self.route = route
        self._viewModel = StateObject(wrappedValue: RouteDetailsViewModel(route: route))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Mini Map Preview
                RouteDetailsMapView(stops: viewModel.currentStops)
                    .frame(height: 250)

                // Route Name Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(route.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    // Route Stats
                    HStack(spacing: 16) {
                        Text("\(viewModel.currentStops.count) stops")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(viewModel.totalDistance)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if !viewModel.distanceFromUserLocation.isEmpty && !viewModel.distanceFromUserLocation.contains("unavailable") {
                            Text(viewModel.distanceFromUserLocation)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }

                // Route Details Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Stops List
                        StopsListSection(stops: viewModel.currentStops)

                        Spacer(minLength: 100) // Extra space for directions button
                    }
                }

                // Directions Button
                Button(action: {
                    showNavigationView = true
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16))
                        Text("Start Navigation")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                        }
                        .foregroundColor(.blue)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showEditView = true
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .fullScreenCover(isPresented: $showEditView) {
            RouteEditView(route: route)
        }
        .fullScreenCover(isPresented: $showNavigationView) {
            RouteNavigationView(route: route)
        }
        .onChange(of: showEditView) { _, isPresented in
            if !isPresented {
                // Refresh the route data when coming back from edit
                viewModel.refreshRouteData()
            }
        }
        .onAppear {
            viewModel.requestLocationPermission()
        }
    }

}

// MARK: - Route Details Map View

struct RouteDetailsMapView: View {
    let stops: [RouteStopEntity]

    @State private var mapPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    @State private var routePolylines: [MKPolyline] = []

    private var routeCoordinates: [CLLocationCoordinate2D] {
        stops.compactMap { stop in
            guard let savedPin = stop.savedPin else { return nil }
            return CLLocationCoordinate2D(latitude: savedPin.latitude, longitude: savedPin.longitude)
        }
    }

    private func updateMapRegion() {
        guard !stops.isEmpty else { return }

        let coordinates = routeCoordinates
        guard !coordinates.isEmpty else { return }

        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.01) * 1.5,
            longitudeDelta: max(maxLon - minLon, 0.01) * 1.5
        )

        let newRegion = MKCoordinateRegion(center: center, span: span)
        mapPosition = .region(newRegion)
    }

    private func fetchRoutePolylines() {
        guard stops.count >= 2 else {
            routePolylines = []
            return
        }

        var newPolylines: [MKPolyline] = []
        let group = DispatchGroup()

        for i in 0..<(stops.count - 1) {
            guard let currentPin = stops[i].savedPin,
                  let nextPin = stops[i + 1].savedPin else { continue }

            let sourceCoordinate = CLLocationCoordinate2D(
                latitude: currentPin.latitude,
                longitude: currentPin.longitude
            )
            let destinationCoordinate = CLLocationCoordinate2D(
                latitude: nextPin.latitude,
                longitude: nextPin.longitude
            )

            group.enter()

            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: sourceCoordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
            request.transportType = .automobile

            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                defer { group.leave() }

                if let route = response?.routes.first {
                    newPolylines.append(route.polyline)
                }
            }
        }

        group.notify(queue: .main) {
            routePolylines = newPolylines
        }
    }

    var body: some View {
        Map(position: $mapPosition) {
            // Add pins for each stop
            ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                if let savedPin = stop.savedPin {
                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: savedPin.latitude, longitude: savedPin.longitude)) {
                        ZStack {
                            if let category = savedPin.category {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(category.symbol)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                    )
                                    .shadow(radius: 4)
                            } else {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 30))
                                    .shadow(radius: 3)
                            }

                            // Order number overlay
                            VStack {
                                Text("\(index + 1)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(Circle().fill(Color.blue))

                                Spacer()
                            }
                            .offset(x: -12, y: -12)
                        }
                    }
                }
            }

            // Add driving route polylines
            ForEach(routePolylines.indices, id: \.self) { index in
                MapPolyline(routePolylines[index])
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .onChange(of: stops) { _, _ in
            updateMapRegion()
            fetchRoutePolylines()
        }
        .onAppear {
            updateMapRegion()
            fetchRoutePolylines()
        }
    }
}


// MARK: - Stops List Section

struct StopsListSection: View {
    let stops: [RouteStopEntity]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stops")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)

            LazyVStack(spacing: 8) {
                ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                    if let savedPin = stop.savedPin {
                        RouteDetailsStopRowView(
                            savedPin: savedPin,
                            order: index + 1
                        )
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }
}

// MARK: - Route Details Stop Row View

struct RouteDetailsStopRowView: View {
    let savedPin: SavedPinEntity
    let order: Int

    var body: some View {
        HStack(spacing: 12) {
            // Order number
            Text("\(order)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.blue))

            // Category icon
            if let category = savedPin.category {
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

            // Pin details
            VStack(alignment: .leading, spacing: 2) {
                Text(savedPin.placeName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(savedPin.shortAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    // Create a sample route for preview
    let context = CoreDataManager.shared.context
    let sampleRoute = RouteEntity(context: context, name: "Sample Route")

    RouteDetailsView(route: sampleRoute)
}