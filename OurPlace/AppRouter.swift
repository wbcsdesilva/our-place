//
//  AppRouter.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-17.
//

import SwiftUI
import CoreData

@MainActor
class AppRouter: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var mapDeepLink: MapDeepLink?
    @Published var shouldStartNavigation: NSManagedObjectID?

    enum Tab: Int, CaseIterable {
        case home = 0
        case map = 1
        case saves = 2
        case events = 3
        case settings = 4
    }

    enum MapDeepLink: Equatable {
        case showPinDetails(NSManagedObjectID)
        case showRouteDetails(NSManagedObjectID)
        case startNavigationToPin(NSManagedObjectID)
    }

    func navigateToPin(_ objectID: NSManagedObjectID) {
        selectedTab = .map
        mapDeepLink = .showPinDetails(objectID)

        // Trigger navigation after a brief delay to allow the pin details to load
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.shouldStartNavigation = objectID
        }
    }

    func navigateToRoute(_ objectID: NSManagedObjectID) {
        selectedTab = .map
        mapDeepLink = .showRouteDetails(objectID)
    }

    func clearNavigationTrigger() {
        shouldStartNavigation = nil
    }
}