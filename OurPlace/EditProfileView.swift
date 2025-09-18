//
//  EditProfileView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-16.
//

import SwiftUI
import PhotosUI
import FirebaseAuth

struct EditProfileView: View {
    let profile: UserProfileEntity?
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Profile Photo Section
                VStack(spacing: 20) {

                    VStack(spacing: 16) {
                        // Current/Selected Photo
                        Group {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else if let profile = profile, profile.hasProfilePhoto,
                                     let imageURL = profile.profileImageURL,
                                     let uiImage = UIImage(contentsOfFile: imageURL.path) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else {
                                // Fallback with initials
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Text(profile?.initials ?? displayName.prefix(1).uppercased())
                                            .font(.largeTitle)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    )
                            }
                        }

                        // Photo Actions
                        HStack(spacing: 20) {
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Text(profile?.hasProfilePhoto == true || profileImage != nil ? "Change Photo" : "Add Photo")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.blue, lineWidth: 2)
                                    )
                            }

                            if profile?.hasProfilePhoto == true || profileImage != nil {
                                Button("Remove") {
                                    removePhoto()
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.red, lineWidth: 2)
                                )
                            }
                        }
                    }
                }

                // Information Section
                VStack(alignment: .leading, spacing: 16) {
                    TextInput(
                        title: "Name",
                        placeholder: "Enter your name",
                        text: $displayName,
                        icon: "person"
                    )

                    TextAreaInput(
                        title: "Bio",
                        placeholder: "Tell us about yourself",
                        text: $bio,
                        minHeight: 80
                    )

                    Text("Your name and bio will be visible to other users.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveProfile()
                }
                .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            loadCurrentValues()
        }
        .onChange(of: selectedPhoto) { oldValue, newValue in
            Task {
                // Only process if we have a new item (not nil from cancel)
                if let newValue = newValue {
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            profileImage = image
                        }
                    }
                }
                // If newValue is nil (canceled), do nothing - keep existing photo
            }
        }
    }

    private func loadCurrentValues() {
        displayName = profile?.displayName ?? ""
        bio = profile?.bio ?? ""
    }

    private func removePhoto() {
        profileImage = nil
        selectedPhoto = nil
        if let profile = profile {
            profile.deleteProfilePhoto()
            do {
                try context.save()
            } catch {
                print("Failed to delete profile photo: \(error)")
            }
        }
    }

    private func saveProfile() {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)

        // Get or create profile with Firebase UID
        let currentProfile: UserProfileEntity
        if let existingProfile = profile {
            currentProfile = existingProfile
        } else {
            let firebaseUID = Auth.auth().currentUser?.uid
            currentProfile = UserProfileEntity(context: context, displayName: trimmedName, firebaseUID: firebaseUID)
        }

        // Update profile info
        currentProfile.updateProfile(displayName: trimmedName, bio: trimmedBio.isEmpty ? nil : trimmedBio)

        // Save profile photo if selected
        if let image = profileImage {
            _ = currentProfile.saveProfilePhoto(image)
        }

        // Save to Core Data
        do {
            try context.save()
            dismiss()
        } catch {
            print("Failed to save profile: \(error)")
        }
    }
}

#Preview {
    EditProfileView(profile: nil)
        .environment(\.managedObjectContext, CoreDataService.shared.context)
}