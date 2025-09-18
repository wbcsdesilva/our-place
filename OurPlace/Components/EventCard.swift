//
//  EventCard.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-18.
//

import SwiftUI

// MARK: - Event Card Component

struct EventCard: View {
    let event: EventEntity
    let currentTime: Date
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let category = event.savedPin?.category {
                Circle()
                    .fill(category.color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(category.symbol)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    )
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.name ?? "Unknown Event")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("At \(event.savedPin?.placeName ?? "Unknown Location")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Text(event.formattedDateTime)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(timeUntilEvent(for: event, from: currentTime))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .contextMenu {
            Button("Delete Event", systemImage: "trash", role: .destructive) {
                onDelete()
            }
        }
    }

    private func timeUntilEvent(for event: EventEntity, from currentTime: Date) -> String {
        guard let startDate = event.startDate else {
            return "Unknown time"
        }

        let timeInterval = startDate.timeIntervalSince(currentTime)

        if timeInterval <= 0 {
            return "Past event"
        }

        let days = Int(timeInterval / (24 * 60 * 60))
        let hours = Int((timeInterval.truncatingRemainder(dividingBy: 24 * 60 * 60)) / (60 * 60))

        if days > 0 {
            return "in \(days) day\(days == 1 ? "" : "s")"
        } else if hours > 0 {
            return "in \(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 60 * 60)) / 60)
            return "in \(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
}

// MARK: - Event Card Small Component

struct EventCardSmall: View {
    let event: EventEntity

    var body: some View {
        HStack(spacing: 12) {
            if let category = event.savedPin?.category {
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
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(event.name ?? "Unknown Event")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("at \(event.savedPin?.placeName ?? "Unknown location")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let startDate = event.startDate {
                    Text(startDate, format: .dateTime.hour().minute())
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }

                Text(event.timeUntilEvent)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .cornerRadius(8)
    }
}

// MARK: - Event Card External Component

struct EventCardExternal: View {
    let title: String
    let location: String?
    let formattedTimeRange: String
    let isAllDay: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Calendar icon (instead of category)
            Circle()
                .fill(Color.gray)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if let location = location, !location.isEmpty {
                    Text("At \(location)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text(formattedTimeRange)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("Calendar Event")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}