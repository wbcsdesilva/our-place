//
//  MainTabView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-01-XX.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        TabView {
            HomeTabView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            MapTabView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Map")
                }
                .tag(1)
            
            SavesTabView()
                .tabItem {
                    Image(systemName: "bookmark.fill")
                    Text("Saves")
                }
                .tag(2)
            
            EventsTabView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Events")
                }
                .tag(3)
            
            SettingsTabView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(4)
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
}
