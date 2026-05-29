//
//  BoutiqueManagerProfileView.swift
//  RSMS
//
//  A premium Profile screen for Boutique Managers.
//  Mirrors the Sales Associate profile design with manager-specific KPIs.
//  All data is fetched from the Supabase backend via DataStore.
//

import SwiftUI

struct BoutiqueManagerProfileView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var dashboardVM = BoutiqueDashboardViewModel()
    @State private var showLogoutConfirmation = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ZStack {
            RSMSTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    if let user = appVM.currentUser {
                        profileHeaderCard(user: user)
                        personalInformationSection(user: user)
                        signOutButton()
                    } else {
                        ContentUnavailableView(
                            "User Session Expired",
                            systemImage: "person.crop.circle.badge.exclamationmark"
                        )
                    }
                }
                .padding(.horizontal, horizontalSizeClass == .regular ? 40 : 20)
                .padding(.vertical, 24)
                .frame(maxWidth: horizontalSizeClass == .regular ? 650 : .infinity)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sign Out", isPresented: $showLogoutConfirmation) {
            Button("Sign Out", role: .destructive) {
                appVM.logout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out? Your current session will be cleared securely.")
        }
        .task {
            if let storeId = appVM.currentStoreId {
                await dashboardVM.load(dataStore: appVM.dataStore, storeId: storeId)
            }
        }
    }

    // MARK: - Profile Header Card

    private func profileHeaderCard(user: UserProfile) -> some View {
        let storeName = user.storeId.map { appVM.dataStore.storeName(for: $0) } ?? "Unknown Store"
        let initials = user.fullName.split(separator: " ").prefix(2)
            .compactMap { $0.first.map(String.init) }.joined().uppercased()

        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.primaryGradient)
                    .frame(width: 80, height: 80)

                Text(initials)
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text(user.fullName)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(RSMSTheme.textPrimary)

                let employeeId = "EMP-\(user.id.uuidString.prefix(8).uppercased())"
                Text("ID: \(employeeId)")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .fontDesign(.monospaced)
            }

            HStack(spacing: 12) {
                Text(user.role.displayName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RSMSTheme.cream)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RSMSTheme.primary, in: Capsule())

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.primary)
                    Text(storeName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RSMSTheme.textSecondary)
                }
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(RSMSTheme.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(RSMSTheme.border, lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, y: 4)
    }



    // MARK: - Personal Information

    private func personalInformationSection(user: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Information")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(RSMSTheme.textPrimary)

            VStack(spacing: 0) {
                infoRow(label: "Email", value: user.email, icon: "envelope")
                Divider().background(RSMSTheme.divider)
                infoRow(label: "Phone", value: user.phone ?? "Not Provided", icon: "phone")
                Divider().background(RSMSTheme.divider)
                infoRow(label: "Role", value: user.role.displayName, icon: "briefcase")
                Divider().background(RSMSTheme.divider)
                infoRow(
                    label: "Store",
                    value: user.storeId.map { appVM.dataStore.storeName(for: $0) } ?? "—",
                    icon: "building.2"
                )
                Divider().background(RSMSTheme.divider)
                infoRow(
                    label: "Member Since",
                    value: user.createdAt.formatted(date: .abbreviated, time: .omitted),
                    icon: "calendar"
                )
            }
            .background(RSMSTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.border, lineWidth: 1))
        }
    }

    private func infoRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(RSMSTheme.textSecondary)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RSMSTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }



    // MARK: - Sign Out

    private func signOutButton() -> some View {
        Button {
            showLogoutConfirmation = true
        } label: {
            HStack {
                Spacer()
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
                    .fontWeight(.semibold)
                Spacer()
            }
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .background(RSMSTheme.primary, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: RSMSTheme.primary.opacity(0.15), radius: 10, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Sign Out")
    }

}


