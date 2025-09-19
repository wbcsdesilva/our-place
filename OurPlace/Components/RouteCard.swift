//
//  RouteCard.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-18.
//

import SwiftUI

// MARK: - Route Card Component

struct RouteCard: View {
    let route: RouteEntity
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // Route name
                Text(route.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Stops and distance info
                Text("\(route.stopCount) stops • \(route.formattedDistance)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Icon and date row
                HStack {
                    // Route icon indicator
                    HStack(spacing: 4) {
                        Image(systemName: "map.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                        Text("Route")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue)
                    .cornerRadius(4)

                    Spacer()

                    // Created date
                    Text(formattedCreatedDateStandard)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }

            }
            .padding(16)
            .background(.regularMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var formattedCreatedDateStandard: String {
        return DateFormatters.standard.string(from: route.createdAt)
    }
}

// MARK: - Route Card Small Component

struct RouteCardSmall: View {
    let route: RouteEntity
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "map.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(route.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("\(route.stopCount) stops • \(route.formattedDistance)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(formattedCreatedDate)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            .padding(12)
            .background(.regularMaterial)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var formattedCreatedDate: String {
        return DateFormatters.short.string(from: route.createdAt)
    }

    private var formattedCreatedDateStandard: String {
        return DateFormatters.standard.string(from: route.createdAt)
    }
}
