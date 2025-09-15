//
//  HomeTabView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-01-XX.
//

import SwiftUI
import FirebaseAuth

struct HomeTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var eventViewModel = EventViewModel()
    @StateObject private var savesViewModel = SavesTabViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Greeting Section
                    WelcomeSection(user: authVM.user)
                        .padding(.top, 16)
                    
                    // Events Today Section
                    EventsTodaySection(eventViewModel: eventViewModel)
                    
                    // Stats Section
                    StatsSection(savesViewModel: savesViewModel)
                    
                    // Quick Actions Section
                    QuickActionsSection()
                    
                    // Recently Saved Section
                    RecentlySavedSection(savesViewModel: savesViewModel)
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 16)
            }
            .navigationBarHidden(true)
            .refreshable {
                eventViewModel.refreshEvents()
                savesViewModel.loadSavedPins()
            }
        }
        .onAppear {
            eventViewModel.loadEvents()
            savesViewModel.loadSavedPins()
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("Welcome, \(userName)!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "house.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Events Today Section
struct EventsTodaySection: View {
    @ObservedObject var eventViewModel: EventViewModel
    
    private var todaysEvents: [EventEntity] {
        eventViewModel.getEventsForDate(Date())
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
                        TodayEventRow(event: event)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
            }
        }
    }
}

struct TodayEventRow: View {
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
                
                Text("at \(event.savedPin?.placeName ?? "Unknown location")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if let eventDate = event.eventDate {
                    Text(eventDate, format: .dateTime.hour().minute())
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Text(event.timeUntilEvent)
                    .font(.caption2)
                    .foregroundColor(.secondary)
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
                count: 0, // TODO: Get a real count here after the routes feature has finished implementation
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

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                QuickActionButton(
                    icon: "mappin.and.ellipse",
                    title: "Add Pin",
                    color: .blue,
                    action: {
                        // TODO: Navigate to add pin
                    }
                )
                
                QuickActionButton(
                    icon: "arrow.trianglehead.turn.up.right.diamond.fill",
                    title: "Navigation",
                    color: .green,
                    action: {
                        // TODO: Start navigation
                    }
                )
                
                QuickActionButton(
                    icon: "calendar.badge.plus",
                    title: "Add Event",
                    color: .orange,
                    action: {
                        // TODO: Navigate to add event
                    }
                )
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(color)
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recently Saved Section
struct RecentlySavedSection: View {
    @ObservedObject var savesViewModel: SavesTabViewModel
    
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
                        RecentPinRow(pin: pin)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
            }
        }
    }
}

struct RecentPinRow: View {
    let pin: SavedPinEntity
    
    var body: some View {
        HStack(spacing: 12) {
            if let category = pin.category {
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
            
            VStack(alignment: .leading, spacing: 2) {
                Text(pin.placeName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(pin.shortAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    HomeTabView()
        .environmentObject(AuthViewModel())
}