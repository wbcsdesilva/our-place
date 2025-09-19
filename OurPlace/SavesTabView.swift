//
//  SavesTabView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-19.
//

import SwiftUI

struct SavesTabView: View {
    @StateObject private var viewModel = SavesTabViewModel()
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        VStack(spacing: 0) {
                // Segmented Picker
                Picker("Content Type", selection: $viewModel.selectedSegment) {
                    Text("Pins").tag(0)
                    Text("Routes").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                // Content based on selected segment
                if viewModel.selectedSegment == 0 {
                    // Pins List
                    if viewModel.filteredPins.isEmpty {
                        EmptyPinsView()
                    } else {
                        PinsListView(pins: viewModel.filteredPins, viewModel: viewModel)
                    }
                } else {
                    // Routes List
                    if viewModel.savedRoutes.isEmpty {
                        EmptyRoutesView()
                    } else {
                        RoutesListView(routes: viewModel.savedRoutes, viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("Saves")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.searchText, prompt: "Search")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if viewModel.selectedSegment == 0 {
                            // TODO: Add pin functionality
                        } else {
                            viewModel.showCreateRoute = true
                        }
                    }
                    .foregroundColor(viewModel.selectedSegment == 0 ? .gray : .blue)
                    .disabled(viewModel.selectedSegment == 0) // Only enable when routes segment is selected
                }
            }
            .onAppear {
                viewModel.refreshPins()
                viewModel.loadSavedRoutes()
            }
            .fullScreenCover(isPresented: $viewModel.showCreateRoute) {
                CreateRouteView()
            }
            .onChange(of: viewModel.showCreateRoute) { _, isPresented in
                if !isPresented {
                    // Refresh routes when coming back from CreateRouteView
                    viewModel.loadSavedRoutes()

                    // Refresh again after a delay to get updated distance calculations
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        viewModel.loadSavedRoutes()
                    }
                }
        }
    }
}

// MARK: - Routes List View

struct RoutesListView: View {
    let routes: [RouteEntity]
    let viewModel: SavesTabViewModel
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(routes, id: \.id) { route in
                    RouteCard(route: route) {
                        router.navigateToRoute(route.objectID)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 8)
        }
    }
}


// MARK: - Pins List View

struct PinsListView: View {
    let pins: [SavedPinEntity]
    let viewModel: SavesTabViewModel
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(pins, id: \.id) { pin in
                    SavedPinCard(
                        pin: pin,
                        action: {
                            router.selectedTab = .map
                            router.mapDeepLink = .showPinDetails(pin.objectID)
                        },
                        showDate: true,
                        dateFormatter: { date in
                            guard let date = date else { return "" }
                            return viewModel.formatDate(date)
                        }
                    )
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 8)
        }
    }
}


// MARK: - Empty States

struct EmptyPinsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Saved Pins")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Your saved pins will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
}

struct EmptyRoutesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Saved Routes")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Your saved routes will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
}

#Preview {
    SavesTabView()
        .environmentObject(AppRouter())
        .environment(\.managedObjectContext, CoreDataService.shared.context)
}
