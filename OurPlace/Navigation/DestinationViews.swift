//
//  DestinationViews.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-17.
//

import SwiftUI
import CoreData

// MARK: - Destination Wrapper Views

struct PinDetailsDestinationView: View {
    let objectID: NSManagedObjectID
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject var router: AppRouter

    var body: some View {
        Group {
            if let savedPin = context.object(with: objectID) as? SavedPinEntity {
                PinDetailsView(
                    savedPin: savedPin,
                    onStartNavigation: { pin in
                        router.navigateToPin(pin.objectID)
                    }
                )
            } else {
                ContentUnavailableView(
                    "Pin Not Found",
                    systemImage: "mappin.slash",
                    description: Text("The requested pin could not be found.")
                )
            }
        }
    }
}

struct RouteDetailsDestinationView: View {
    let objectID: NSManagedObjectID
    @Environment(\.managedObjectContext) private var context

    var body: some View {
        Group {
            if let route = context.object(with: objectID) as? RouteEntity {
                RouteDetailsView(route: route)
            } else {
                ContentUnavailableView(
                    "Route Not Found",
                    systemImage: "road.lanes.curved.left",
                    description: Text("The requested route could not be found.")
                )
            }
        }
    }
}