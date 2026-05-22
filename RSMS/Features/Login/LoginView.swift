//
//  LoginView.swift
//  RSMS
//
//  Luxury role-selection login screen for iPad.
//

import SwiftUI

struct LoginView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var email = ""
    @State private var password = ""
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
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

                // Login Form
                loginForm
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)

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

    // MARK: - Login Form

    private var loginForm: some View {
        VStack(spacing: 24) {
            Text("Sign in to your account")
                .font(.headline)
                .foregroundStyle(RSMSTheme.textPrimary)
            
            if let error = viewModel.authError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(RSMSTheme.danger)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(RSMSTheme.danger.opacity(0.1))
                .cornerRadius(8)
            }
            
            VStack(spacing: 16) {
                // Email Field
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(RSMSTheme.gold)
                        .frame(width: 24)
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .focused($isEmailFocused)
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                .padding()
                .background(RSMSTheme.surfaceSecondary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isEmailFocused ? RSMSTheme.gold : Color.clear, lineWidth: 1)
                )
                
                // Password Field
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(RSMSTheme.gold)
                        .frame(width: 24)
                    SecureField("Password", text: $password)
                        .focused($isPasswordFocused)
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                .padding()
                .background(RSMSTheme.surfaceSecondary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isPasswordFocused ? RSMSTheme.gold : Color.clear, lineWidth: 1)
                )
            }
            
            // Login Button
            Button(action: {
                Task {
                    await viewModel.login(email: email, password: password)
                }
            }) {
                HStack {
                    Spacer()
                    if viewModel.isAuthenticating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                            .font(.headline)
                    }
                    Spacer()
                }
                .padding()
                .background(RSMSTheme.goldGradient)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: RSMSTheme.gold.opacity(0.3), radius: 10, y: 4)
            }
            .disabled(email.isEmpty || password.isEmpty || viewModel.isAuthenticating)
            .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
            
            // Demo fallback for quick testing
            Menu {
                Button("Boutique Manager (Sophie)") {
                    viewModel.login(as: .boutiqueManager)
                }
                Button("Sales Associate (Lucas)") {
                    viewModel.login(as: .salesAssociate)
                }
                Button("Inventory Controller (Emma)") {
                    viewModel.login(as: .inventoryController)
                }
                Button("Client Portal (Isabelle)") {
                    viewModel.login(as: .client)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                    Text("Bypass Login (Offline Demo)")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(RSMSTheme.textTertiary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(RSMSTheme.surfaceSecondary, in: Capsule())
                .overlay(Capsule().stroke(RSMSTheme.border, lineWidth: 1))
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: 400)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(RSMSTheme.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(RSMSTheme.gold.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 30, y: 15)
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
}

#Preview {
    LoginView()
        .environment(AppViewModel())
}
