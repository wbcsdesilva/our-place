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
    @State private var showAddStops = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Route Details Form
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Route Name Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Route Name")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter route name", text: $viewModel.routeName)
                                .textFieldStyle(.roundedBorder)
                        }
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
                                    showAddStops = true
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
                
                // Bottom Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        viewModel.createRoute()
                    }) {
                        HStack {
                            if viewModel.isCreatingRoute {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(viewModel.isCreatingRoute ? "Creating..." : "Create")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canCreateRoute ? Color.blue : Color(.systemGray4))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!viewModel.canCreateRoute || viewModel.isCreatingRoute)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .background(.regularMaterial)
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
            }
        }
        .fullScreenCover(isPresented: $showAddStops) {
            AddStopsView(
                onStopSelected: { selectedPin in
                    viewModel.addStop(selectedPin)
                }
            )
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