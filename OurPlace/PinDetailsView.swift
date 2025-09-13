//
//  PinDetailsView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-21.
//

import SwiftUI
import MapKit
import CoreLocation
import QuickLook

struct PinDetailsView: View {
    let savedPin: SavedPinEntity
    @Environment(\.dismiss) private var dismiss
    @State private var showQuickLook = false
    @State private var quickLookURLs: [URL] = []
    @State private var quickLookStartIndex = 0
    
    var onStartNavigation: ((SavedPinEntity) -> Void)?
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                VStack(spacing: 24) {
                    PinDetailsMapPreview(savedPin: savedPin)
                        .frame(height: 200)
                        .cornerRadius(16)
                        .padding(.top, 16)
                    
                    VStack(spacing: 16) {
                        Text(savedPin.placeName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(savedPin.address)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if let category = savedPin.category {
                            HStack {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text(category.symbol)
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                    )
                                
                                Text(category.name)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        CoordinatesDisplay(coordinate: savedPin.coordinate)
                    }
                    
                    
                    EventsSection(savedPin: savedPin)
                    
                    if let notes = savedPin.notes, !notes.isEmpty {
                        NotesDisplaySection(notes: notes)
                    }
                    
                    if !savedPin.photoFilePathsArray.isEmpty {
                        PhotosDisplaySection(
                            photoFilePaths: savedPin.photoFilePathsArray,
                            onPhotoTap: { index in
                                openPhotosInQuickLook(startingAt: index)
                            }
                        )
                    }
                    
                    if !savedPin.attachmentFilePathsArray.isEmpty {
                        AttachmentsDisplaySection(
                            attachmentFilePaths: savedPin.attachmentFilePathsArray,
                            onAttachmentTap: { index in
                                openAttachmentsInQuickLook(startingAt: index)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button(action: {
                        onStartNavigation?(savedPin)
                        dismiss()
                    }) {
                        Image(systemName: "arrow.trianglehead.turn.up.right.diamond.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Pin Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        // TODO: Navigate to edit pin screen
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showQuickLook) {
            QuickLookView(urls: quickLookURLs, startIndex: quickLookStartIndex)
        }
    }
    
    
    private func openPhotosInQuickLook(startingAt index: Int) {
        let photoURLs = savedPin.photoFilePathsArray.compactMap { path in
            resolveFilePath(path)
        }
        
        guard !photoURLs.isEmpty else { return }
        
        quickLookURLs = photoURLs
        quickLookStartIndex = min(index, photoURLs.count - 1)
        showQuickLook = true
    }
    
    private func openAttachmentsInQuickLook(startingAt index: Int) {
        let attachmentURLs = savedPin.attachmentFilePathsArray.compactMap { path in
            resolveFilePath(path)
        }
        
        guard !attachmentURLs.isEmpty else { return }
        
        quickLookURLs = attachmentURLs
        quickLookStartIndex = min(index, attachmentURLs.count - 1)
        showQuickLook = true
    }
    
}


struct PinDetailsMapPreview: View {
    let savedPin: SavedPinEntity
    
    var body: some View {
        Map(initialPosition: .region(
            MKCoordinateRegion(
                center: savedPin.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )) {
            Annotation("", coordinate: savedPin.coordinate, anchor: .bottom) {
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
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                        .font(.system(size: 30))
                        .shadow(radius: 3)
                }
            }
        }
        .allowsHitTesting(false)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}




struct EventsSection: View {
    let savedPin: SavedPinEntity
    @State private var events: [EventEntity] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Events")
                .font(.headline)
                .foregroundColor(.primary)
            
            if events.isEmpty {
                Text("No events scheduled at this location")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                TimelineView(.periodic(from: .now, by: 5.0)) { context in
                    VStack(spacing: 8) {
                        ForEach(events, id: \.id) { event in
                            EventRow(
                                title: event.name ?? "Unknown Event",
                                date: event.formattedDateTime,
                                daysUntil: event.timeUntilEvent
                            )
                        }
                    }
                }
            }
        }
        .onAppear {
            loadEvents()
        }
    }
    
    private func loadEvents() {
        events = EventEntity.fetchEventsForSavedPin(savedPin, context: savedPin.managedObjectContext!)
    }
}

struct EventRow: View {
    let title: String
    let date: String
    let daysUntil: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(daysUntil)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}


struct NotesDisplaySection: View {
    let notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(notes)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
}


struct PhotosDisplaySection: View {
    let photoFilePaths: [String]
    let onPhotoTap: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(Array(photoFilePaths.enumerated()), id: \.offset) { index, path in
                        Button(action: {
                            onPhotoTap(index)
                        }) {
                            Group {
                                if let uiImage = loadImageFromPath(path) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            VStack(spacing: 4) {
                                                Image(systemName: "photo")
                                                    .foregroundColor(.gray)
                                                    .font(.system(size: 20))
                                                Text("Failed")
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(12)
        }
    }
    
    private func loadImageFromPath(_ path: String) -> UIImage? {
        guard let url = resolveFilePath(path) else {
            print("Failed to resolve file path: \(path)")
            return nil
        }
        
        if let image = UIImage(contentsOfFile: url.path) {
            return image
        }
        
        print("Failed to load image from resolved path: \(url.path)")
        return nil
    }
}


struct AttachmentsDisplaySection: View {
    let attachmentFilePaths: [String]
    let onAttachmentTap: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attachments")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ForEach(Array(attachmentFilePaths.enumerated()), id: \.offset) { index, path in
                    AttachmentDisplayRow(
                        filePath: path,
                        onTap: {
                            onAttachmentTap(index)
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
}

struct AttachmentDisplayRow: View {
    let filePath: String
    let onTap: () -> Void
    
    private var fileName: String {
        URL(fileURLWithPath: filePath).lastPathComponent
    }
    
    private var fileExtension: String {
        URL(fileURLWithPath: filePath).pathExtension.lowercased()
    }
    
    private var attachmentType: AttachmentType {
        determineAttachmentType(from: URL(fileURLWithPath: filePath))
    }
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            HStack(spacing: 12) {
                Image(systemName: attachmentType.icon)
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                
                Text(fileName)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}


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


struct QuickLookView: UIViewControllerRepresentable {
    let urls: [URL]
    let startIndex: Int
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        controller.currentPreviewItemIndex = startIndex
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let parent: QuickLookView
        
        init(_ parent: QuickLookView) {
            self.parent = parent
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return parent.urls.count
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.urls[index] as QLPreviewItem
        }
    }
}


private func resolveFilePath(_ path: String) -> URL? {
    let fileManager = FileManager.default
    let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    // Determine the full path
    let fullPath: String
    if path.hasPrefix("/") {
        // Absolute path - try as is first, then convert to relative if it fails
        if fileManager.fileExists(atPath: path) {
            fullPath = path
        } else {
            // Extract relative part and try with current documents directory
            if let range = path.range(of: "SavedPins/") {
                let relativePart = String(path[range.lowerBound...])
                fullPath = documentsPath.appendingPathComponent(relativePart).path
            } else {
                return nil
            }
        }
    } else {
        // Relative path - construct full path with current documents directory
        fullPath = documentsPath.appendingPathComponent(path).path
    }
    
    // Check if file exists and return URL
    return fileManager.fileExists(atPath: fullPath) ? URL(fileURLWithPath: fullPath) : nil
}

#Preview {
    let context = CoreDataManager.shared.context
    let mockCategory = CategoryEntity(
        context: context,
        name: "Restaurants",
        symbol: "🍕",
        color: Color.orange
    )
    
    let mockPin = SavedPinEntity(
        context: context,
        placeName: "Pizza Hut - Tangalle",
        address: "150 Matara Rd, Tangalle",
        coordinate: CLLocationCoordinate2D(latitude: 6.7852, longitude: 6.7852),
        notes: "Tangalle Pizza Hut\nVery close to the Tangalle Bus Stand\n\nThe Sausage Crust Pizza is nice",
        category: mockCategory
    )
    
    PinDetailsView(savedPin: mockPin)
}