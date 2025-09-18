//
//  CreateRouteView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-15.
//

import SwiftUI
import MapKit

struct CreateRouteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateRouteViewModel()
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Route Details Form
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Route Name Input
                        TextInput(
                            title: "Route Name",
                            placeholder: "Enter route name",
                            text: $viewModel.routeName
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        // Stops Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Stops")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Spacer()

                                // Add stops button
                                Button(action: {
                                    navigationPath.append(RouteFlowDestination.addStops)
                                }) {
                                    Image(systemName: "plus")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            if viewModel.routeStops.isEmpty {
                                EmptyStopsView()
                            } else {
                                List {
                                    ForEach(viewModel.routeStops.sorted(by: { $0.order < $1.order })) { stop in
                                        RouteStopRowView(
                                            stop: stop,
                                            onRemove: {
                                                viewModel.removeStop(stop)
                                            }
                                        )
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    }
                                }
                                .listStyle(PlainListStyle())
                                .scrollDisabled(true)
                                .frame(height: CGFloat(viewModel.routeStops.count) * 80)
                            }
                        }
                        
                        Spacer(minLength: 80)
                    }
                }
                
            }
            .navigationTitle("Create Route")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.createRoute()
                    }) {
                        HStack {
                            if viewModel.isCreatingRoute {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            }
                            Text(viewModel.isCreatingRoute ? "Creating..." : "Create")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!viewModel.canCreateRoute || viewModel.isCreatingRoute)
                }
            }
            .navigationDestination(for: RouteFlowDestination.self) { destination in
                switch destination {
                case .addStops:
                    AddStopsView(
                        onStopSelected: { selectedPin in
                            viewModel.addStop(selectedPin)
                            navigationPath.removeLast()
                        }
                    )
                }
            }
        }
        .onChange(of: viewModel.routeCreated) { _, created in
            if created {
                dismiss()
            }
        }
    }
}


#Preview {
    CreateRouteView()
}