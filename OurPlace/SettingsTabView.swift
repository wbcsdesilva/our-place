//
//  SettingsTabView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-16.
//

import SwiftUI
import FirebaseAuth
import CoreData

struct SettingsTabView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject var authViewModel: AuthViewModel

    // Apple way: @FetchRequest automatically updates when Core Data changes
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserProfileEntity.updatedAt, ascending: false)]
    ) private var allProfiles: FetchedResults<UserProfileEntity>

    // Computed property to get current user's profile
    var userProfile: UserProfileEntity? {
        guard let firebaseUID = authViewModel.user?.uid else { return nil }
        return allProfiles.first { $0.firebaseUID == firebaseUID }
    }

    var body: some View {
        List {
                // Profile Section
                Section {
                    if let userProfile = userProfile {
                        ProfileHeaderView(profile: userProfile)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                        NavigationLink("Edit Profile") {
                            EditProfileView(profile: userProfile)
                        }
                        .foregroundColor(.blue)
                    } else {
                        Text("Loading profile...")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Profile")
                }

                // App Settings Section
                Section {
                    HStack {
                        Image(systemName: "car.fill")
                            .foregroundColor(.blue)
                            .frame(width: 25)
                        Text("Default Transport Mode")
                        Spacer()
                        Text("Driving")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "ruler")
                            .foregroundColor(.orange)
                            .frame(width: 25)
                        Text("Units")
                        Spacer()
                        Text("Metric")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Preferences")
                }

                // Account Section
                Section {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                            .frame(width: 25)
                        Text("Email")
                        Spacer()
                        Text(authViewModel.user?.email ?? "Not available")
                            .foregroundColor(.secondary)
                    }

                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                                .frame(width: 25)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("Account")
                }
        }
        .navigationTitle("Settings")
        .onAppear {
            ensureProfileExists()
        }
    }

    private func ensureProfileExists() {
        guard let firebaseUID = authViewModel.user?.uid else { return }

        // Check if profile exists, if not create it
        if allProfiles.first(where: { $0.firebaseUID == firebaseUID }) == nil {
            let _ = UserProfileEntity.getProfile(for: firebaseUID, context: context)
            do {
                try context.save()
            } catch {
                print("Failed to create initial profile: \(error)")
            }
        }
    }
}

// MARK: - Profile Header View

struct ProfileHeaderView: View {
    @ObservedObject var profile: UserProfileEntity

    var body: some View {
        HStack(spacing: 16) {
            // Profile Photo
            Group {
                if profile.hasProfilePhoto,
                   let imageURL = profile.profileImageURL,
                   let uiImage = UIImage(contentsOfFile: imageURL.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } else {
                    // Fallback with initials
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(profile.initials)
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )
                }
            }

            // Profile Info
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName)
                    .font(.title2)
                    .fontWeight(.bold)

                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    SettingsTabView()
        .environmentObject(AuthViewModel())
        .environment(\.managedObjectContext, CoreDataManager.shared.context)
}
