//
//  MainTabView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-16.
//

import SwiftUI
import CoreData

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var router: AppRouter
    @State private var mapNavigationPath = NavigationPath()
    @State private var savesNavigationPath = NavigationPath()

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack {
                HomeTabView()
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(AppRouter.Tab.home)

            NavigationStack(path: $mapNavigationPath) {
                MapTabView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        switch destination {
                        case .pinDetails(let objectID):
                            PinDetailsDestinationView(objectID: objectID)
                        case .routeDetails(let objectID):
                            RouteDetailsDestinationView(objectID: objectID)
                        }
                    }
                    .onChange(of: router.mapDeepLink) { _, link in
                        guard let link else { return }
                        switch link {
                        case .showPinDetails(let objectID):
                            mapNavigationPath = NavigationPath()
                            mapNavigationPath.append(NavigationDestination.pinDetails(objectID))
                        case .showRouteDetails(let objectID):
                            mapNavigationPath = NavigationPath()
                            mapNavigationPath.append(NavigationDestination.routeDetails(objectID))
                        case .startNavigationToPin(let objectID):
                            mapNavigationPath = NavigationPath()
                            mapNavigationPath.append(NavigationDestination.pinDetails(objectID))
                        }
                        router.mapDeepLink = nil
                    }
            }
            .tabItem {
                Image(systemName: "map.fill")
                Text("Map")
            }
            .tag(AppRouter.Tab.map)

            NavigationStack(path: $savesNavigationPath) {
                SavesTabView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        switch destination {
                        case .pinDetails(let objectID):
                            PinDetailsDestinationView(objectID: objectID)
                        case .routeDetails(let objectID):
                            RouteDetailsDestinationView(objectID: objectID)
                        }
                    }
            }
            .tabItem {
                Image(systemName: "bookmark.fill")
                Text("Saves")
            }
            .tag(AppRouter.Tab.saves)

            NavigationStack {
                EventsTabView()
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Events")
            }
            .tag(AppRouter.Tab.events)

            NavigationStack {
                SettingsTabView()
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("Settings")
            }
            .tag(AppRouter.Tab.settings)
        }
        .accentColor(.blue)
        .onAppear {
            // Configure tab bar appearance for material background
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            tabBarAppearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
            
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppRouter())
}
