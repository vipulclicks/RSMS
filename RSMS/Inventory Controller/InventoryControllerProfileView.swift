//
//  InventoryControllerProfileView.swift
//  RSMS
//
//  Profile page for the Inventory Controller role.
//  Live data is pulled from Supabase on appear via AppViewModel.refreshCurrentUser().
//  Avatar is rendered from UserProfile.avatarURL using AsyncImage.
//

import SwiftUI

// MARK: - Profile View

struct InventoryControllerProfileView: View {

    @Environment(AppViewModel.self) private var viewModel
    @State private var showLogoutConfirmation = false
    @State private var showEditProfile        = false
    @State private var showChangePassword     = false
    @State private var showNotificationPrefs  = false
    @State private var showAbout              = false
    @State private var storeName: String      = "—"

    // ── Derived ──────────────────────────────────────────────────────

    private var user: UserProfile? { viewModel.currentUser }

    private var initials: String {
        guard let name = user?.fullName else { return "IC" }
        let parts = name.components(separatedBy: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last  = parts.dropFirst().first?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }

    private var memberSince: String {
        guard let date = user?.createdAt else { return "—" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: date)
    }

    private var avatarURL: URL? {
        guard let raw = user?.avatarURL, !raw.isEmpty else { return nil }
        return URL(string: raw)
    }

    // ── Body ─────────────────────────────────────────────────────────

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroCard
                statsRow
                accountSection
                dangerSection
            }
            .padding(24)
        }
        .background(RSMSTheme.background)
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.inline)
        // ── Fetch live data from Supabase ──────────────────────────
        .task {
            await refresh()
            await fetchStoreName()
        }
        // ── Confirmation Alert for Logout ──────────────────────────
        .alert("Sign Out?", isPresented: $showLogoutConfirmation) {
            Button("Sign Out", role: .destructive) { viewModel.logout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll be returned to the login screen.")
        }
        // ── Sheets ────────────────────────────────────────────────
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(user: user)
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordSheet()
        }
        .sheet(isPresented: $showNotificationPrefs) {
            NotificationPrefsSheet()
        }
        .sheet(isPresented: $showAbout) {
            AboutSheet()
        }
    }

    // ── Data helpers ─────────────────────────────────────────────────

    private func refresh() async {
        await viewModel.refreshCurrentUser()
    }

    private func fetchStoreName() async {
        guard let storeId = user?.storeId else { return }
        if let store = viewModel.dataStore.stores.first(where: { $0.id == storeId }) {
            storeName = store.name
            return
        }
        do {
            let store = try await viewModel.dataStore.fetchStore(id: storeId)
            storeName = store.name
        } catch {
            storeName = "—"
        }
    }

    // ── Hero Card ─────────────────────────────────────────────────────

    private var heroCard: some View {
        VStack(spacing: 20) {

            // ── Avatar ────────────────────────────────────────────
            avatarView
                .frame(width: 96, height: 96)
                .shadow(color: RSMSTheme.primary.opacity(0.35), radius: 16, x: 0, y: 8)

            // ── Name + Role Badge ─────────────────────────────────
            VStack(spacing: 6) {
                Text(user?.fullName ?? "Inventory Controller")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RSMSTheme.textPrimary)

                HStack(spacing: 6) {
                    Image(systemName: "shippingbox.fill")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.gold)
                    Text(user?.role.displayName ?? "Inventory Controller")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.gold)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(RSMSTheme.gold.opacity(0.12))
                .clipShape(Capsule())
            }

            // ── Contact Chips ─────────────────────────────────────
            VStack(spacing: 8) {
                if let email = user?.email {
                    contactChip(icon: "envelope.fill", label: email)
                }
                if let phone = user?.phone {
                    contactChip(icon: "phone.fill", label: phone)
                }
            }

            // ── Member Since ──────────────────────────────────────
            Text("Member since \(memberSince)")
                .font(.caption)
                .foregroundStyle(RSMSTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .rsmsCard()
    }

    // ── Avatar (AsyncImage + initials fallback) ───────────────────────

    @ViewBuilder
    private var avatarView: some View {
        if let url = avatarURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    initialsCircle
                        .overlay(
                            ProgressView()
                                .tint(RSMSTheme.cream)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                case .failure:
                    initialsCircle
                @unknown default:
                    initialsCircle
                }
            }
        } else {
            initialsCircle
        }
    }

    private var initialsCircle: some View {
        ZStack {
            Circle()
                .fill(RSMSTheme.primaryGradient)
            Text(initials)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.cream)
        }
    }

    // ── Stats Row ──────────────────────────────────────────────────────

    private var statsRow: some View {
        HStack(spacing: 16) {
            statCard(
                icon:  "checkmark.seal.fill",
                value: (user?.isActive == true) ? "Active" : "Inactive",
                label: "Status",
                color: (user?.isActive == true) ? RSMSTheme.success : RSMSTheme.danger
            )
            statCard(
                icon:  "shippingbox.circle.fill",
                value: "IC",
                label: "Access Level",
                color: RSMSTheme.info
            )
            statCard(
                icon:  "building.2.fill",
                value: user?.storeId != nil ? "1" : "—",
                label: "Store",
                color: RSMSTheme.gold
            )
        }
    }

    // ── Account Section ────────────────────────────────────────────────

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("ACCOUNT")

            // Store Info card
            storeInfoCard

            // Settings rows
            VStack(spacing: 0) {
                settingsRow(
                    icon: "person.crop.circle.fill",
                    iconColor: RSMSTheme.gold,
                    title: "Edit Profile",
                    subtitle: "Update your name and details"
                ) { showEditProfile = true }

                divider

                settingsRow(
                    icon: "lock.rotation",
                    iconColor: RSMSTheme.info,
                    title: "Change Password",
                    subtitle: "Update your account password"
                ) { showChangePassword = true }

                divider

                NavigationLink(destination: MFASettingsView()) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(RSMSTheme.primary.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(RSMSTheme.primary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Multi-Factor Authentication")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RSMSTheme.textPrimary)
                            Text("Manage two-step verification")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RSMSTheme.textTertiary)
                    }
                    .padding(16)
                }
                .buttonStyle(.plain)

                divider

                settingsRow(
                    icon: "bell.badge.fill",
                    iconColor: RSMSTheme.warning,
                    title: "Notification Preferences",
                    subtitle: "Manage alerts and notifications"
                ) { showNotificationPrefs = true }

                divider

                settingsRow(
                    icon: "info.circle.fill",
                    iconColor: RSMSTheme.textSecondary,
                    title: "About RSMS",
                    subtitle: "Version & system information"
                ) { showAbout = true }
            }
            .background(RSMSTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(RSMSTheme.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        }
    }

    // ── Store Info Card (live from Supabase) ───────────────────────────

    private var storeInfoCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(RSMSTheme.gold.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "building.2.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(RSMSTheme.gold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Assigned Store")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
                Text(storeName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .redacted(reason: storeName == "—" ? .placeholder : [])
            }

            Spacer()

            Image(systemName: "mappin.circle.fill")
                .font(.title3)
                .foregroundStyle(RSMSTheme.gold.opacity(0.5))
        }
        .padding(16)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(RSMSTheme.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    // ── Danger Section ─────────────────────────────────────────────────

    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("SESSION")

            Button {
                showLogoutConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                .background(RSMSTheme.goldGradient)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: RSMSTheme.gold.opacity(0.3), radius: 10, y: 4)
            }
        }
    }

    // ── Reusable Sub-Views ─────────────────────────────────────────────

    private func contactChip(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(RSMSTheme.gold)
            Text(label)
                .font(.caption)
                .foregroundStyle(RSMSTheme.textSecondary)
                .lineLimit(1)
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(RSMSTheme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(RSMSTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RSMSTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 3)
    }

    private func settingsRow(
        icon: String, iconColor: Color,
        title: String, subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(iconColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RSMSTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textTertiary)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Rectangle()
            .fill(RSMSTheme.divider)
            .frame(height: 0.5)
            .padding(.leading, 72)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .tracking(2)
            .foregroundStyle(RSMSTheme.gold)
            .padding(.leading, 4)
    }
}

// MARK: - Edit Profile Sheet

private struct EditProfileSheet: View {
    let user: UserProfile?
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = ""
    @State private var phone: String    = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    LabeledContent("Full Name") {
                        TextField("Full Name", text: $fullName)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Phone") {
                        TextField("Phone", text: $phone)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.phonePad)
                    }
                    LabeledContent("Email") {
                        Text(user?.email ?? "—")
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Role") {
                    LabeledContent("Role") {
                        Text(user?.role.displayName ?? "—")
                            .foregroundStyle(.secondary)
                    }
                }
                Section {
                    Button("Save Profile") {
                        // TODO: Persist changes via DataStore.updateUser
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.background)
                    .listRowBackground(RSMSTheme.gold)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                fullName = user?.fullName ?? ""
                phone    = user?.phone    ?? ""
            }
        }
    }
}

// MARK: - Change Password Sheet

private struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM

    @State private var currentPassword = ""
    @State private var newPassword     = ""
    @State private var confirmPassword = ""
    @State private var isUpdating      = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Current") {
                    SecureField("Current Password", text: $currentPassword)
                }
                Section("New Password") {
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
                }
                Section {
                    Button("Update Password") {
                        guard newPassword == confirmPassword, !newPassword.isEmpty else { return }
                        Task {
                            isUpdating = true
                            await appVM.updatePassword(newPassword: newPassword)
                            isUpdating = false
                            dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.background)
                    .listRowBackground(
                        (isUpdating || newPassword.isEmpty || newPassword != confirmPassword)
                        ? RSMSTheme.gold.opacity(0.5)
                        : RSMSTheme.gold
                    )
                }
                .disabled(isUpdating || newPassword.isEmpty || newPassword != confirmPassword)
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Notification Prefs Sheet

private struct NotificationPrefsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var lowStockAlerts      = true
    @State private var cycleCountReminders = true
    @State private var transferUpdates     = false
    @State private var dailySummary        = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Inventory Alerts") {
                    Toggle("Low Stock Alerts", isOn: $lowStockAlerts)
                        .tint(RSMSTheme.gold)
                    Toggle("Cycle Count Reminders", isOn: $cycleCountReminders)
                        .tint(RSMSTheme.gold)
                    Toggle("Transfer Updates", isOn: $transferUpdates)
                        .tint(RSMSTheme.gold)
                }
                Section("Reports") {
                    Toggle("Daily Summary", isOn: $dailySummary)
                        .tint(RSMSTheme.gold)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .tint(RSMSTheme.gold)
                }
            }
        }
    }
}

// MARK: - About Sheet

private struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let appVersion  = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        NavigationStack {
            Form {
                Section("Application") {
                    LabeledContent("App Name", value: "RSMS")
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Build", value: buildNumber)
                    LabeledContent("Role Module", value: "Inventory Controller")
                }
                Section("Organisation") {
                    LabeledContent("Brand", value: "Maison Lumière")
                    LabeledContent("Platform", value: "iOS / iPadOS")
                }
            }
            .navigationTitle("About RSMS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .tint(RSMSTheme.gold)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        InventoryControllerProfileView()
            .environment(AppViewModel())
    }
}
