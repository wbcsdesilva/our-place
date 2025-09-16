//
//  RouteComponents.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-16.
//

import SwiftUI

// MARK: - Route Stop Row View
struct RouteStopRowView: View {
    let stop: RouteStop
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Order number
            Text("\(stop.order)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.blue))

            // Category icon
            if let category = stop.savedPin.category {
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
                Text(stop.savedPin.placeName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(stop.savedPin.shortAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Empty Stops View
struct EmptyStopsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("No stops added yet")
                .font(.body)
                .foregroundColor(.secondary)

            Text("Tap the + button to add stops from your saved pins")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }
}