//
//  LoginView.swift
//  RSMS
//
//  Luxury role-selection login screen for iPad.
//

import SwiftUI

struct LoginView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = LoginViewModel()
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
                .foregroundStyle(RSMSTheme.primaryGradient)

            Text("MAISON LUMIÈRE")
                .font(.system(size: 36, weight: .light, design: .serif))
                .tracking(8)
                .foregroundStyle(RSMSTheme.primaryGradient)

            Rectangle()
                .fill(RSMSTheme.primaryGradient)
                .frame(width: 60, height: 1)

            Text("RETAIL STORE MANAGEMENT")
                .font(.system(size: 13, weight: .medium))
                .tracking(4)
                .foregroundStyle(RSMSTheme.textSecondary)
        }
    }

    // MARK: - Role Card

    private func roleCard(for role: UserRole) -> some View {
        let info = viewModel.roleInfo(for: role)

        return Button {
            withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
                appViewModel.login(as: role)
            }
        } label: {
            VStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(RSMSTheme.primary.opacity(0.1))
                        .frame(width: 72, height: 72)
                    Image(systemName: info.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(RSMSTheme.primary)
                }

                // Role name
                Text(role.displayName)
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.textPrimary)

                // User name
                Text(info.userName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RSMSTheme.primary)

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
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(RSMSTheme.primary.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.2), radius: 30, y: 15)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Background Decoration

    private var backgroundDecoration: some View {
        ZStack {
            // Subtle animated glows for a premium feel
            Circle()
                .fill(RSMSTheme.primary.opacity(0.05))
                .blur(radius: 120)
                .frame(width: 600, height: 600)
                .offset(x: appeared ? -200 : -250, y: appeared ? -300 : -350)
                .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: appeared)

            Circle()
                .fill(RSMSTheme.surfaceTertiary.opacity(0.4))
                .blur(radius: 100)
                .frame(width: 500, height: 500)
                .offset(x: appeared ? 300 : 350, y: appeared ? 200 : 250)
                .animation(.easeInOut(duration: 12).repeatForever(autoreverses: true), value: appeared)
        }
    }

}


#Preview {
    LoginView()
        .environment(AppViewModel())
}
