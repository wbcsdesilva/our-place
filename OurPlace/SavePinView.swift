//
//  SavePinView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-18.
//

import SwiftUI
import MapKit
import CoreLocation
import PhotosUI
import UniformTypeIdentifiers

struct SavePinView: View {
    let pin: DroppedPin
    let placeName: String
    let address: String
    @State private var editedPlaceName: String
    @State private var selectedCategory = "🍕 Snacks"
    @State private var notes = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var loadedImages: [UIImage] = []
    @State private var attachments: [AttachmentItem] = []
    @State private var showDocumentPicker = false
    @Environment(\.dismiss) private var dismiss
    
    init(pin: DroppedPin, placeName: String, address: String) {
        self.pin = pin
        self.placeName = placeName
        self.address = address
        self._editedPlaceName = State(initialValue: placeName)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Map Preview
                    MapPreview(pin: pin)
                        .frame(height: 200)
                        .cornerRadius(16)
                        .padding(.top, 16)
                    
                    VStack(spacing: 16) {
                        // Place Name TextField
                        CustomTextField(
                            placeholder: "Place name",
                            text: $editedPlaceName,
                            icon: "mappin.and.ellipse"
                        )
                        
                        // Address Display (Non-editable)
                        AddressDisplay(address: address)
                        
                        // Coordinates Display
                        CoordinatesDisplay(coordinate: pin.coordinate)
                    }
                    
                    // Category Section
                    CategorySection(selectedCategory: $selectedCategory)
                    
                    // Notes Section
                    NotesSection(notes: $notes)
                    
                    // Photos Section
                    PhotosSection(
                        selectedPhotos: $selectedPhotos,
                        loadedImages: $loadedImages
                    )
                    
                    // Attachments Section
                    AttachmentsSection(
                        attachments: $attachments,
                        showDocumentPicker: $showDocumentPicker
                    )
                    
                    // Save Button
                    CustomButton(
                        title: "Save pin",
                        action: {
                            // TODO: Implement save functionality
                            dismiss()
                        },
                        backgroundColor: .blue
                    )
                    .padding(.top, 8)
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
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
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
    @Binding var selectedCategory: String
    @State private var showCategoryPicker = false
    
    let categories = [
        "🍕 Snacks", "🍽️ Restaurant", "☕ Cafe", "🏪 Shop", "🏥 Medical",
        "⛽ Gas Station", "🏦 Bank", "🎬 Entertainment", "🏨 Hotel", "🚗 Parking"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Category")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "pencil.tip.crop.circle.badge.plus.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                        .frame(width: 32, height: 32)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            Button(action: { showCategoryPicker.toggle() }) {
                HStack {
                    Text(selectedCategory)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(.yellow)
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            .cornerRadius(12)
        }
        .actionSheet(isPresented: $showCategoryPicker) {
            ActionSheet(
                title: Text("Select Category"),
                buttons: categories.map { category in
                    .default(Text(category)) {
                        selectedCategory = category
                    }
                } + [.cancel()]
            )
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