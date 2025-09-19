//
//  SavePinView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-18.
//

import SwiftUI
import MapKit
import CoreLocation
import CoreData
import PhotosUI
import UniformTypeIdentifiers

struct SavePinView: View {
    @StateObject private var viewModel: SavePinViewModel
    @State private var showDocumentPicker = false
    @State private var navigationPath = NavigationPath()
    @State private var selectedCategoryID: NSManagedObjectID?
    @State private var showCategoryPicker = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CategoryEntity.name, ascending: true)],
        animation: .default
    )
    private var categories: FetchedResults<CategoryEntity>

    private var selectedCategory: CategoryEntity? {
        guard let selectedCategoryID = selectedCategoryID else { return nil }
        return context.object(with: selectedCategoryID) as? CategoryEntity
    }

    private var isFormValid: Bool {
        !viewModel.editedPlaceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedCategory != nil
    }
    
    let onSaveSuccess: () -> Void
    let onCancel: () -> Void
    
    init(pin: DroppedPin, placeName: String, address: String, onSaveSuccess: @escaping () -> Void = {}, onCancel: @escaping () -> Void = {}) {
        self.onSaveSuccess = onSaveSuccess
        self.onCancel = onCancel
        self._viewModel = StateObject(wrappedValue: SavePinViewModel(
            pin: pin,
            placeName: placeName,
            address: address
        ))
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 24) {
                    // Map Preview
                    MapPreview(pin: viewModel.pin)
                        .frame(height: 200)
                        .cornerRadius(16)
                        .padding(.top, 16)
                    
                    VStack(spacing: 16) {
                        // Place Name TextField
                        TextInput(
                            title: "Place Name",
                            placeholder: "Enter place name",
                            text: $viewModel.editedPlaceName,
                            icon: "mappin.and.ellipse"
                        )
                        
                        // Address Display (Non-editable)
                        AddressDisplay(address: viewModel.address)
                        
                        // Coordinates Display
                        CoordinatesDisplay(coordinate: viewModel.pin.coordinate)
                    }
                    
                    // Category Section
                    CategorySection(
                        categories: Array(categories),
                        selectedCategory: selectedCategory,
                        onCategorySelected: { _ in
                            showCategoryPicker = true
                        },
                        onCreateCategory: {
                            navigationPath.append(SaveFlowDestination.createCategory)
                        }
                    )
                    
                    // Notes Section
                    NotesSection(notes: $viewModel.notes)
                    
                    // Photos Section
                    PhotosSection(
                        selectedPhotos: $viewModel.selectedPhotos,
                        loadedImages: $viewModel.loadedImages
                    )
                    
                    // Attachments Section
                    AttachmentsSection(
                        attachments: $viewModel.attachments,
                        showDocumentPicker: $showDocumentPicker
                    )
                    
                    // Save Button
                    CustomButton(
                        title: "Save pin",
                        action: {
                            viewModel.savePin(selectedCategory: selectedCategory, context: context)
                            if viewModel.savedSuccessfully {
                                onSaveSuccess()
                            }
                            dismiss()
                        },
                        isLoading: viewModel.isLoading,
                        backgroundColor: isFormValid ? .blue : .gray
                    )
                    .disabled(!isFormValid)
                    .padding(.top, 8)
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Save Pin")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationDestination(for: SaveFlowDestination.self) { destination in
                switch destination {
                case .createCategory:
                    CreateCategoryView(onCategoryCreated: { categoryID in
                        selectedCategoryID = categoryID
                        navigationPath.removeLast()
                    })
                }
            }
            .fullScreenCover(isPresented: $showCategoryPicker) {
                CategoryPickerView(
                    categories: Array(categories),
                    selectedCategory: selectedCategory,
                    onCategorySelected: { (category: CategoryEntity) in
                        selectedCategoryID = category.objectID
                        showCategoryPicker = false
                    },
                    onCreateCategory: {
                        showCategoryPicker = false
                        navigationPath.append(SaveFlowDestination.createCategory)
                    }
                )
            }
        }
    }
}

// MARK: - Map Preview Component

struct MapPreview: View {
    let pin: DroppedPin
    @State private var cameraPosition: MapCameraPosition
    
    init(pin: DroppedPin) {
        self.pin = pin
        self._cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: pin.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        ))
    }
    
    var body: some View {
        Map(position: .constant(cameraPosition)) {
            Annotation("Saved Pin", coordinate: pin.coordinate, anchor: .bottom) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.red)
                    .font(.system(size: 24))
                    .shadow(radius: 2)
            }
        }
        .mapControlVisibility(.hidden)
        .disabled(true)
    }
}

// MARK: - Coordinates Display Component

struct CoordinatesDisplay: View {
    let coordinate: CLLocationCoordinate2D
    
    var body: some View {
        HStack(spacing: 16) {
            CoordinateItem(
                label: "Latitude",
                value: coordinate.latitude,
                icon: "globe"
            )
            
            CoordinateItem(
                label: "Longitude", 
                value: coordinate.longitude,
                icon: "globe"
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

struct CoordinateItem: View {
    let label: String
    let value: Double
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.system(size: 14))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.4f", value))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Address Display Component

struct AddressDisplay: View {
    let address: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "location")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Address")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(address.isEmpty ? "Loading address..." : address)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Category Section Component

struct CategorySection: View {
    let categories: [CategoryEntity]
    let selectedCategory: CategoryEntity?
    let onCategorySelected: (CategoryEntity) -> Void
    let onCreateCategory: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Category")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: onCreateCategory) {
                    Image(systemName: "pencil.tip.crop.circle.badge.plus.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                        .frame(width: 32, height: 32)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            Button(action: { onCategorySelected(CategoryEntity()) }) {
                HStack {
                    if let selectedCategory = selectedCategory {
                        Text(selectedCategory.displayText)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(selectedCategory.color)
                            .cornerRadius(6)
                    } else {
                        Text("Select Category")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(.gray.opacity(0.2))
                            .cornerRadius(6)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Notes Section Component

struct NotesSection: View {
    @Binding var notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(.primary)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $notes)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(12)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .background(.regularMaterial)
                    .cornerRadius(12)
                
                if notes.isEmpty {
                    Text("Add your notes here...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

// MARK: - Data Models

struct AttachmentItem: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let type: AttachmentType
}

enum AttachmentType {
    case pdf
    case audio
    case image
    case video
    case text
    case word
    case excel
    case powerpoint
    case archive
    case other
    
    var icon: String {
        switch self {
        case .pdf: return "doc.fill"
        case .audio: return "waveform"
        case .image: return "photo.fill"
        case .video: return "video.fill"
        case .text: return "text.document.fill"
        case .word: return "doc.text.fill"
        case .excel: return "tablecells.fill"
        case .powerpoint: return "play.rectangle.fill"
        case .archive: return "archivebox.fill"
        case .other: return "doc.fill"
        }
    }
}

// MARK: - Photos Section Component

struct PhotosSection: View {
    @Binding var selectedPhotos: [PhotosPickerItem]
    @Binding var loadedImages: [UIImage]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photos")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    Image(systemName: "photo.badge.plus")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                        .frame(width: 32, height: 32)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            if loadedImages.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .foregroundColor(.secondary)
                        .font(.system(size: 24))
                    
                    Text("No photos added")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(.regularMaterial)
                .cornerRadius(12)
                .transition(.opacity.combined(with: .scale))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(loadedImages.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: loadedImages[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        loadedImages.remove(at: index)
                                        if index < selectedPhotos.count {
                                            selectedPhotos.remove(at: index)
                                        }
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                        .font(.system(size: 16))
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(.regularMaterial)
                .cornerRadius(12)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .onChange(of: selectedPhotos) { oldValue, newValue in
            Task {
                loadedImages.removeAll()
                for item in newValue {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            loadedImages.append(image)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Attachments Section Component

struct AttachmentsSection: View {
    @Binding var attachments: [AttachmentItem]
    @Binding var showDocumentPicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Attachments")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { showDocumentPicker = true }) {
                    Image(systemName: "document.badge.plus.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                        .frame(width: 32, height: 32)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            if attachments.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc")
                        .foregroundColor(.secondary)
                        .font(.system(size: 24))
                    
                    Text("No attachments added")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(.regularMaterial)
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(attachments) { attachment in
                        AttachmentRow(
                            attachment: attachment,
                            onRemove: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if let index = attachments.firstIndex(where: { $0.id == attachment.id }) {
                                        attachments.remove(at: index)
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(.regularMaterial)
                .cornerRadius(12)
            }
        }
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.pdf, .audio, .plainText, .item],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                DispatchQueue.main.async {
                    for url in urls {
                        // Only access security-scoped resources if needed
                        let accessing = url.startAccessingSecurityScopedResource()
                        defer {
                            if accessing {
                                url.stopAccessingSecurityScopedResource()
                            }
                        }
                        
                        let attachment = AttachmentItem(
                            name: url.lastPathComponent,
                            url: url,
                            type: determineAttachmentType(from: url)
                        )
                        attachments.append(attachment)
                    }
                }
            case .failure(let error):
                print("Document picker error: \(error.localizedDescription)")
            }
        }
    }
}

struct AttachmentRow: View {
    let attachment: AttachmentItem
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: attachment.type.icon)
                .foregroundColor(.secondary)
                .font(.system(size: 16))
            
            Text(attachment.name)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}

// MARK: - Helper Functions

private func determineAttachmentType(from url: URL) -> AttachmentType {
    let pathExtension = url.pathExtension.lowercased()
    switch pathExtension {
    case "pdf":
        return .pdf
    case "m4a", "mp3", "wav", "aac", "flac", "ogg":
        return .audio
    case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic":
        return .image
    case "mp4", "mov", "avi", "mkv", "wmv", "flv":
        return .video
    case "txt", "md", "rtf":
        return .text
    case "doc", "docx":
        return .word
    case "xls", "xlsx", "csv":
        return .excel
    case "ppt", "pptx":
        return .powerpoint
    case "zip", "rar", "7z", "tar", "gz":
        return .archive
    default:
        return .other
    }
}

// MARK: - Category Picker View

struct CategoryPickerView: View {
    let categories: [CategoryEntity]
    let selectedCategory: CategoryEntity?
    let onCategorySelected: (CategoryEntity) -> Void
    let onCreateCategory: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if categories.isEmpty {
                    VStack(spacing: 24) {
                        Spacer()

                        Image(systemName: "tag")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No Categories Available")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("Create your first category to organize your pins")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button(action: onCreateCategory) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Create Category")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(categories, id: \.id) { category in
                                CategoryPickerRow(
                                    category: category,
                                    isSelected: selectedCategory?.objectID == category.objectID,
                                    onTap: {
                                        onCategorySelected(category)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

struct CategoryPickerRow: View {
    let category: CategoryEntity
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Category icon with color
                Circle()
                    .fill(category.color)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(category.symbol)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    )

                // Category name
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SavePinView(
        pin: DroppedPin(
            id: UUID(),
            coordinate: CLLocationCoordinate2D(latitude: 37.4419, longitude: -122.1419),
            timestamp: Date()
        ),
        placeName: "Pizza Hut - Tangalle",
        address: "150 Matara Rd, Tangalle"
    )
}
