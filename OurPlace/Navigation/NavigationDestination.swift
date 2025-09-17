//
//  NavigationDestination.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-17.
//

import Foundation
import CoreData

// MARK: - Navigation Destinations

// Main tab navigation
enum NavigationDestination: Hashable {
    case pinDetails(NSManagedObjectID)
    case routeDetails(NSManagedObjectID)
}

// Save pin flow navigation
enum SaveFlowDestination: Hashable {
    case createCategory
}

// Route flow navigation (for CreateRoute and RouteEdit)
enum RouteFlowDestination: Hashable {
    case addStops
}