//
//  LoginView.swift
//  RSMS
//
//  Luxury role-selection login screen for iPad.
//

import SwiftUI

struct LoginView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Background
            RSMSTheme.background.ignoresSafeArea()
            backgroundDecoration

            VStack(spacing: 0) {
                Spacer()

                // Branding
                brandingSection
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -20)

                Spacer().frame(height: 60)

                // Role Cards
                HStack(spacing: 24) {
                    ForEach(Array(UserRole.allCases.enumerated()), id: \.element.id) { index, role in
                        roleCard(for: role)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 30)
                            .animation(.spring(duration: 0.7, bounce: 0.3).delay(Double(index) * 0.15 + 0.3), value: appeared)
                    }
                }
                .padding(.horizontal, 60)

                Spacer().frame(height: 48)

                // Footer
                Text("Select your role to continue")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textTertiary)
                    .opacity(appeared ? 1 : 0)

                Spacer()

                // Store info
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                    Text("Paris Vendôme · Maison Lumière")
                }
                .font(.caption)
                .foregroundStyle(RSMSTheme.textTertiary)
                .padding(.bottom, 30)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }

    // MARK: - Branding

    private var brandingSection: some View {
        VStack(spacing: 12) {
            // Diamond icon
            Image(systemName: "diamond.fill")
                .font(.system(size: 32))
                .foregroundStyle(RSMSTheme.goldGradient)

            Text("MAISON LUMIÈRE")
                .font(.system(size: 36, weight: .light, design: .serif))
                .tracking(8)
                .foregroundStyle(RSMSTheme.goldGradient)

            Rectangle()
                .fill(RSMSTheme.goldGradient)
                .frame(width: 60, height: 1)

            Text("RETAIL STORE MANAGEMENT")
                .font(.system(size: 13, weight: .medium))
                .tracking(4)
                .foregroundStyle(RSMSTheme.textSecondary)
        }
    }

    // MARK: - Role Card

    private func roleCard(for role: UserRole) -> some View {
        let info = roleInfo(for: role)

        return Button {
            withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
                viewModel.login(as: role)
            }
        } label: {
            VStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(RSMSTheme.gold.opacity(0.1))
                        .frame(width: 72, height: 72)
                    Image(systemName: info.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(RSMSTheme.gold)
                }

                // Role name
                Text(role.displayName)
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)

                // User name
                Text(info.userName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.gold)

                // Description
                Text(info.description)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 34)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(RSMSTheme.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(RSMSTheme.gold.opacity(0.15), lineWidth: 1)
                    )
            )
            .shadow(color: RSMSTheme.gold.opacity(0.05), radius: 20, y: 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Background Decoration

    private var backgroundDecoration: some View {
        ZStack {
            Circle()
                .fill(RSMSTheme.gold.opacity(0.03))
                .frame(width: 600, height: 600)
                .offset(x: -200, y: -300)
            Circle()
                .fill(RSMSTheme.gold.opacity(0.02))
                .frame(width: 400, height: 400)
                .offset(x: 300, y: 200)
        }
    }

    // MARK: - Helpers

    private struct RoleInfo {
        let icon: String
        let userName: String
        let description: String
    }

    private func roleInfo(for role: UserRole) -> RoleInfo {
        switch role {
        case .boutiqueManager:
            return RoleInfo(icon: "building.columns.fill", userName: "Sophie Martin", description: "Dashboard, staff scheduling & store operations")
        case .salesAssociate:
            return RoleInfo(icon: "person.crop.circle.fill", userName: "Lucas Dubois", description: "Clienteling, appointments & remote selling")
        case .inventoryController:
            return RoleInfo(icon: "shippingbox.fill", userName: "Emma Leroy", description: "RFID stock management & tracking")
        }
    }
}

#Preview {
    LoginView()
        .environment(AppViewModel())
}
