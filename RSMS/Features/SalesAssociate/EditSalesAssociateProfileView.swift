//
//  EditSalesAssociateProfileView.swift
//  RSMS
//
//  Created by Antigravity on 2026-06-01.
//

import SwiftUI
import PhotosUI

struct EditSalesAssociateProfileView: View {
    let profile: UserProfile
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var phone: String = ""
    @State private var avatarURL: String = ""
    
    // Photo picking states
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var uiImage: UIImage? = nil
    @State private var showCameraPicker = false
    @State private var showPhotosPicker = false

    @State private var isSaving = false

    init(profile: UserProfile) {
        self.profile = profile
        self._phone = State(initialValue: profile.phone ?? "")
        self._avatarURL = State(initialValue: profile.avatarURL ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // Interactive Profile Photo Header
                        profilePhotoHeader
                        
                        // 1. Personal Details Card (Editable)
                        // Note: Employee Name is moved to the read-only section below.
                        // Photo URL textfield is removed in favor of the interactive picker.
                        LuxuryFormCard(title: "Contact Details", icon: "phone.fill") {
                            VStack(spacing: 16) {
                                LuxuryTextField(title: "Phone Number", text: $phone)
                                    .keyboardType(.phonePad)
                            }
                        }

                        // 2. Company Managed Details (Locked/Read-Only)
                        LuxuryFormCard(title: "Company Managed Details", icon: "lock.shield.fill") {
                            VStack(alignment: .leading, spacing: 18) {
                                // Locked information disclaimer banner
                                HStack(spacing: 10) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundStyle(RSMSTheme.primary)
                                        .font(.subheadline)
                                    
                                    Text("These fields are managed centrally and locked. To change them, please contact your boutique manager.")
                                        .font(.caption)
                                        .foregroundStyle(RSMSTheme.textSecondary)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(12)
                                .background(RSMSTheme.primary.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                
                                Divider().background(RSMSTheme.divider)

                                // Full Name (Read-Only)
                                lockedRow(label: "Full Name", value: profile.fullName, icon: "person.circle")

                                // Email Address (Read-Only)
                                lockedRow(label: "Email Address", value: profile.email, icon: "envelope")

                                // Employee ID
                                let employeeId = "EMP-\(profile.id.uuidString.prefix(8).uppercased())"
                                lockedRow(label: "Employee ID", value: employeeId, icon: "number")

                                // Store / Location
                                let storeName = profile.storeId.map { appViewModel.dataStore.storeName(for: $0) } ?? "Unknown Store"
                                lockedRow(label: "Boutique Store", value: storeName, icon: "mappin.circle")

                                // Designation / Role
                                let roleName = profile.role.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
                                lockedRow(label: "Designation", value: roleName, icon: "briefcase")

                                // Hire Date
                                let hireDateString = profile.createdAt.formatted(date: .abbreviated, time: .omitted)
                                lockedRow(label: "Hire Date", value: hireDateString, icon: "calendar")

                                // Employment Status
                                lockedRow(label: "Employment Status", value: "Active", icon: "checkmark.seal")
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(RSMSTheme.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .font(.headline)
                    .foregroundStyle(isSaving ? Color.gray : RSMSTheme.primary)
                    .disabled(isSaving)
                }
            }
            .sheet(isPresented: $showCameraPicker) {
                ImagePicker(sourceType: .camera) { pickedImage in
                    self.uiImage = pickedImage
                }
            }
            .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            self.uiImage = image
                        }
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var profilePhotoHeader: some View {
        let initials = profile.fullName.split(separator: " ").prefix(2)
            .compactMap { $0.first.map(String.init) }.joined().uppercased()

        return VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                if let image = uiImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(RSMSTheme.border, lineWidth: 1))
                } else {
                    ProfileAvatarView(avatarURL: avatarURL, initials: initials, size: 100)
                }

                // Camera overlay badge
                ZStack {
                    Circle()
                        .fill(RSMSTheme.primary)
                        .frame(width: 32, height: 32)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .offset(x: 4, y: 4)
                .shadow(color: Color.black.opacity(0.1), radius: 4)
            }
            .contentShape(Circle())
            .overlay {
                Menu {
                    Button {
                        showCameraPicker = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                    }
                    
                    Button {
                        showPhotosPicker = true
                    } label: {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    }

                    if uiImage != nil || !avatarURL.isEmpty {
                        Button(role: .destructive) {
                            withAnimation {
                                self.uiImage = nil
                                self.avatarURL = ""
                                self.selectedPhotoItem = nil
                            }
                        } label: {
                            Label("Remove Photo", systemImage: "trash")
                        }
                    }
                } label: {
                    Color.clear
                        .contentShape(Circle())
                }
            }
            
            Text("Tap photo to change")
                .font(.caption2.weight(.medium))
                .foregroundStyle(RSMSTheme.textSecondary)
                .padding(.top, 4)
        }
        .padding(.vertical, 12)
    }

    private func lockedRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(RSMSTheme.textTertiary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
                
                HStack(spacing: 6) {
                    Text(value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textSecondary)
                    
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.textTertiary)
                }
            }
            Spacer()
        }
    }

    // MARK: - Image Persistence Operations

    private func saveImageLocally(image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsDirectory = paths.first else { return nil }
        
        let fileURL = documentsDirectory.appendingPathComponent("avatar_\(profile.id.uuidString.lowercased()).jpg")
        do {
            try data.write(to: fileURL)
            print("[EditProfile] Image saved locally: \(fileURL)")
            return fileURL
        } catch {
            print("[EditProfile] Error writing image data locally: \(error)")
            return nil
        }
    }

    private func uploadToSupabase(image: UIImage) async -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        do {
            let pathName = "\(profile.id.uuidString.lowercased()).jpg"
            print("[EditProfile] Uploading image to Supabase avatars/\(pathName)")
            let path = try await appViewModel.dataStore.api.uploadStorage(
                bucket: "avatars",
                path: pathName,
                data: data,
                contentType: "image/jpeg"
            )
            // Construct public URL representation
            let publicURL = "\(SupabaseConfig.projectURL)/storage/v1/object/public/\(path)"
            print("[EditProfile] Uploaded. Public URL: \(publicURL)")
            return publicURL
        } catch {
            print("[EditProfile] Supabase upload failed: \(error.localizedDescription)")
            return nil
        }
    }

    private func saveProfile() {
        isSaving = true

        Task {
            var finalAvatarURL = avatarURL
            
            if let pickedImage = uiImage {
                // Save locally first to guarantee instant offline persistence
                if let localURL = saveImageLocally(image: pickedImage) {
                    finalAvatarURL = localURL.absoluteString
                }
                
                // Attempt Supabase cloud upload
                if let cloudURL = await uploadToSupabase(image: pickedImage) {
                    finalAvatarURL = cloudURL
                }
            }
            
            // Save local overrides in UserDefaults for robust local/offline persistence
            let idStr = profile.id.uuidString.lowercased()
            UserDefaults.standard.set(phone.trimmingCharacters(in: .whitespaces), forKey: "phone_\(idStr)")
            UserDefaults.standard.set(finalAvatarURL, forKey: "avatar_\(idStr)")

            let updatedProfile = UserProfile(
                id: profile.id,
                email: profile.email, // Locked and uneditable
                fullName: profile.fullName, // Locked and uneditable
                role: profile.role,
                storeId: profile.storeId,
                avatarURL: finalAvatarURL.isEmpty ? nil : finalAvatarURL,
                phone: phone.trimmingCharacters(in: .whitespaces).isEmpty ? nil : phone.trimmingCharacters(in: .whitespaces),
                isActive: profile.isActive,
                createdAt: profile.createdAt,
                updatedAt: Date()
            )

            do {
                try await appViewModel.dataStore.updateEmployeeProfile(updatedProfile)
                
                await MainActor.run {
                    withAnimation(.smooth(duration: 0.3)) {
                        appViewModel.currentUser = updatedProfile
                    }
                    isSaving = false
                    dismiss()
                }
            } catch {
                print("[EditSalesAssociateProfileView] Failed to save profile to database: \(error.localizedDescription)")
                
                // Fallback local update to keep UI in sync
                await MainActor.run {
                    if let idx = appViewModel.dataStore.users.firstIndex(where: { $0.id == profile.id }) {
                        appViewModel.dataStore.users[idx] = updatedProfile
                    }
                    withAnimation(.smooth(duration: 0.3)) {
                        appViewModel.currentUser = updatedProfile
                    }
                    isSaving = false
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    let vm = AppViewModel()
    vm.currentUser = .previewAssociate
    return EditSalesAssociateProfileView(profile: .previewAssociate)
        .environment(vm)
}
