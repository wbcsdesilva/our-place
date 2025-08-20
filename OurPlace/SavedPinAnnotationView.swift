//
//  SavedPinAnnotationView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-19.
//

import SwiftUI

// MARK: - SavedPinAnnotationView

struct SavedPinAnnotationView: View {
    let annotation: SavedPinAnnotation
    @State private var showLabel = true
    var onTap: ((SavedPinAnnotation) -> Void)?
    
    var body: some View {
        VStack(spacing: 4) {
            // Custom Pin with Category
            ZStack {
                // Pin background with category color
                Circle()
                    .fill(annotation.savedPin.category?.color ?? .gray)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                // Category emoji
                if let category = annotation.savedPin.category {
                    Text(category.symbol)
                        .font(.system(size: 16))
                        .fontWeight(.medium)
                }
            }
            
            // Place name label
            if showLabel {
                Text(annotation.savedPin.placeName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.black.opacity(0.7))
                    )
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    .lineLimit(1)
                    .animation(.easeInOut(duration: 0.2), value: showLabel)
            }
        }
        .onTapGesture {
            // Center map when tapped
            onTap?(annotation)
        }
        .allowsHitTesting(true) // Ensure this view consumes tap events
    }
}