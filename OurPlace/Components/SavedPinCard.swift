//
//  SavedPinCard.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-18.
//


import SwiftUI

// MARK: - Saved Pin Card Component
struct SavedPinCard: View {
    let pin: SavedPinEntity
    let action: () -> Void
    var showDate: Bool = true
    var dateFormatter: ((Date?) -> String)?

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // Pin name
                Text(pin.placeName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Address
                Text(pin.shortAddress)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Category and date row
                HStack {
                    // Category
                    if let category = pin.category {
                        Text(category.displayText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(category.color)
                            .cornerRadius(4)
                    }

                    Spacer()

                    // Date (if enabled)
                    if showDate {
                        Text(formattedDate)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(.regularMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var formattedDate: String {
        if let formatter = dateFormatter {
            return formatter(pin.createdAt)
        } else {
            // Default formatting
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            return formatter.string(from: pin.createdAt)
        }
    }
}

