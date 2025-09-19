//
//  HomeTabView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-16.
//

import SwiftUI
import FirebaseAuth
import CoreData

struct HomeTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var router: AppRouter
    @StateObject private var eventViewModel = EventViewModel()
    @StateObject private var savesViewModel = SavesTabViewModel()

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EventEntity.startDate, ascending: true)],
        animation: .default
    )
    private var allEvents: FetchedResults<EventEntity>
    
    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                    // Welcome Greeting Section
                    WelcomeSection(user: authVM.user)
                        .padding(.top, 16)
                    
                    // Events Today Section
                    EventsTodaySection(allEvents: Array(allEvents))
                    
                    // Stats Section
                    StatsSection(savesViewModel: savesViewModel)
                    
                    // Recently Saved Pins Section
                    RecentlySavedSection(savesViewModel: savesViewModel, router: router)

                    // Recently Saved Routes Section
                    RecentlySavedRoutesSection(savesViewModel: savesViewModel, router: router)
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 16)
            }
            .navigationBarHidden(true)
            .refreshable {
                eventViewModel.refreshEvents()
                savesViewModel.loadSavedPins()
                savesViewModel.loadSavedRoutes()
            }
            .onAppear {
                savesViewModel.loadSavedPins()
                savesViewModel.loadSavedRoutes()
            }
    }
}

// MARK: - Welcome Section
struct WelcomeSection: View {
    let user: FirebaseAuth.User?
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
    
    private var userName: String {
        if let user = user {
            if let displayName = user.displayName, !displayName.isEmpty {
                return displayName.components(separatedBy: " ").first ?? displayName
            } else if let email = user.email {
                return email.components(separatedBy: "@").first ?? "there"
            }
        }
        return "there"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Welcome, \(userName)!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Events Today Section
struct EventsTodaySection: View {
    let allEvents: [EventEntity]

    private var todaysEvents: [EventEntity] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return allEvents.filter { event in
            guard let startDate = event.startDate else { return false }
            return startDate >= startOfDay && startDate < endOfDay
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Events")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if todaysEvents.isEmpty {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.gray)
                        .font(.title2)
                    
                    Text("No events scheduled for today")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(todaysEvents, id: \.id) { event in
                        EventCardSmall(event: event)
                    }
                }
            }
        }
    }
}


// MARK: - Stats Section
struct StatsSection: View {
    @ObservedObject var savesViewModel: SavesTabViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            StatCard(
                icon: "mappin.circle.fill",
                title: "Pins Saved",
                count: savesViewModel.savedPins.count,
                color: .blue
            )
            
            StatCard(
                icon: "map.fill",
                title: "Routes Saved",
                count: savesViewModel.savedRoutes.count,
                color: .green
            )
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}


// MARK: - Recently Saved Section
struct RecentlySavedSection: View {
    @ObservedObject var savesViewModel: SavesTabViewModel
    let router: AppRouter
    
    private var recentPins: [SavedPinEntity] {
        Array(savesViewModel.savedPins.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recently Saved")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if recentPins.isEmpty {
                HStack {
                    Image(systemName: "mappin.slash")
                        .foregroundColor(.gray)
                        .font(.title2)
                    
                    Text("No saved pins yet")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentPins, id: \.id) { pin in
                        SavedPinCardSmall(pin: pin) {
                            router.selectedTab = .map
                            router.mapDeepLink = .showPinDetails(pin.objectID)
                        }
                    }
                }
            }
        }
    }
}


// MARK: - Recently Saved Routes Section
struct RecentlySavedRoutesSection: View {
    @ObservedObject var savesViewModel: SavesTabViewModel
    let router: AppRouter

    private var recentRoutes: [RouteEntity] {
        Array(savesViewModel.savedRoutes.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recently Saved Routes")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)

            if recentRoutes.isEmpty {
                HStack {
                    Image(systemName: "map")
                        .foregroundColor(.gray)
                        .font(.title2)

                    Text("No saved routes yet")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentRoutes, id: \.id) { route in
                        RouteCardSmall(route: route) {
                            router.navigateToRoute(route.objectID)
                        }
                    }
                }
            }
        }
    }
}


#Preview {
    HomeTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppRouter())
}
