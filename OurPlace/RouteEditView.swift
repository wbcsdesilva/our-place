//
//  RouteEditView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-15.
//

import SwiftUI
import MapKit

struct RouteEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditRouteViewModel
    @State private var navigationPath = NavigationPath()

    init(route: RouteEntity) {
        self._viewModel = StateObject(wrappedValue: EditRouteViewModel(route: route))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                routeDetailsContent
                bottomButtons
            }
            .navigationTitle("Edit Route")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                toolbarContent
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
        .onChange(of: viewModel.changesSaved) { _, saved in
            if saved {
                dismiss()
            }
        }
    }


    private var routeDetailsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                routeNameInput
                stopsSection
                Spacer(minLength: 80)
            }
        }
    }

    private var routeNameInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Route Name")
                .font(.headline)
                .foregroundColor(.primary)

            TextField("Enter route name", text: $viewModel.routeName)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var stopsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            stopsHeader
            stopsContent
        }
    }

    private var stopsHeader: some View {
        HStack {
            Text("Stops")
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            addButton
        }
        .padding(.horizontal, 16)
    }

    private var addButton: some View {
        Button(action: {
            navigationPath.append(RouteFlowDestination.addStops)
        }) {
            Image(systemName: "plus")
                .font(.title2)
                .foregroundColor(.blue)
        }
    }

    @ViewBuilder
    private var stopsContent: some View {
        if viewModel.routeStops.isEmpty {
            EmptyStopsView()
        } else {
            stopsList
        }
    }

    @ViewBuilder
    private var stopsList: some View {
        let stopCount: Int = viewModel.routeStops.count
        let height: CGFloat = CGFloat(stopCount * 80)
        let sortedStops = viewModel.routeStops.sorted(by: { $0.order < $1.order })

        List {
            ForEach(sortedStops) { stop in
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
        .listStyle(.plain)
        .scrollDisabled(true)
        .frame(height: height)
    }


    private var bottomButtons: some View {
        HStack(spacing: 16) {
            cancelButton
            saveButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(.regularMaterial)
    }

    private var cancelButton: some View {
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
    }

    private var saveButton: some View {
        let buttonText: String = viewModel.isSaving ? "Saving..." : "Save Changes"
        let backgroundColor: Color = viewModel.canSave ? Color.blue : Color(.systemGray4)
        let isDisabled: Bool = !viewModel.canSave || viewModel.isSaving

        return Button(action: {
            viewModel.saveChanges()
        }) {
            HStack {
                if viewModel.isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(buttonText)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isDisabled)
    }

    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
    }
}


#Preview {
    let context = CoreDataManager.shared.context
    let sampleRoute = RouteEntity(context: context, name: "Sample Route")

    RouteEditView(route: sampleRoute)
}