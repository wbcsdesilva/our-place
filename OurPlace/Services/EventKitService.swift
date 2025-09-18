//
//  EventKitService.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-17.
//

import Foundation
import EventKit
import Combine

@MainActor
class EventKitService: ObservableObject {
    static let shared = EventKitService()

    @Published var hasCalendarAccess = false
    @Published var shouldRefresh = false

    private let eventStore = EKEventStore()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupEventStoreObserver()
        checkCurrentAccessStatus()
    }

    private func setupEventStoreObserver() {
        NotificationCenter.default
            .publisher(for: .EKEventStoreChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.shouldRefresh.toggle()
            }
            .store(in: &cancellables)
    }

    private func checkCurrentAccessStatus() {
        if #available(iOS 17.0, *) {
            hasCalendarAccess = EKEventStore.authorizationStatus(for: .event) == .fullAccess
        } else {
            hasCalendarAccess = EKEventStore.authorizationStatus(for: .event) == .authorized
        }
    }

    func requestAccessIfNeeded() async -> Bool {
        let currentStatus = EKEventStore.authorizationStatus(for: .event)

        // If already authorized, return true
        if #available(iOS 17.0, *) {
            if currentStatus == .fullAccess {
                await MainActor.run {
                    hasCalendarAccess = true
                }
                return true
            }
        } else {
            if currentStatus == .authorized {
                await MainActor.run {
                    hasCalendarAccess = true
                }
                return true
            }
        }

        // If denied, return false
        if currentStatus == .denied || currentStatus == .restricted {
            await MainActor.run {
                hasCalendarAccess = false
            }
            return false
        }

        // Request access
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestWriteOnlyAccessToEvents()
            }

            await MainActor.run {
                hasCalendarAccess = granted
            }
            return granted
        } catch {
            await MainActor.run {
                hasCalendarAccess = false
            }
            return false
        }
    }

    func fetchEvents(from startDate: Date, to endDate: Date, calendars: [EKCalendar]? = nil) -> [EKEvent] {
        guard hasCalendarAccess else { return [] }

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )

        return eventStore.events(matching: predicate)
    }

    func getAvailableCalendars() -> [EKCalendar] {
        guard hasCalendarAccess else { return [] }
        return eventStore.calendars(for: .event)
    }
}

extension EKEventStore {
    @available(iOS 17.0, *)
    func requestFullAccessToEvents() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            requestFullAccessToEvents { granted, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func requestWriteOnlyAccessToEvents() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            requestWriteOnlyAccessToEvents { granted, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}