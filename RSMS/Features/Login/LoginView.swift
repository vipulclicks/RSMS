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
    @State private var showForgotPassword = false
    @State private var resetEmail = ""

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

            // Forgot Password
            HStack {
                Spacer()
                Button {
                    resetEmail = email  // Pre-fill with current email
                    showForgotPassword = true
                } label: {
                    Text("Forgot Password?")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RSMSTheme.gold)
                }
            }
            .padding(.top, -8)

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
        .sheet(isPresented: $showForgotPassword) {
            forgotPasswordSheet
        }
    }

    // MARK: - Forgot Password Sheet

    private var forgotPasswordSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 48))
                    .foregroundStyle(RSMSTheme.goldGradient)
                    .padding(.top, 20)

                Text("Reset Your Password")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)

                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Reset email field
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(RSMSTheme.gold)
                        .frame(width: 24)
                    TextField("Email Address", text: $resetEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .foregroundStyle(RSMSTheme.textPrimary)
                }
                .padding()
                .background(RSMSTheme.surfaceSecondary)
                .cornerRadius(12)
                .padding(.horizontal)

                // Success message
                if let success = viewModel.resetSuccessMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(success)
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RSMSTheme.success)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(RSMSTheme.success.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }

                // Error message
                if let error = viewModel.resetError {
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
                    .padding(.horizontal)
                }

                // Send Reset Link Button
                Button {
                    Task {
                        await viewModel.requestPasswordReset(email: resetEmail)
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isResettingPassword {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Send Reset Link")
                                .font(.headline)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(RSMSTheme.goldGradient)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(resetEmail.isEmpty || viewModel.isResettingPassword)
                .opacity(resetEmail.isEmpty ? 0.6 : 1.0)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showForgotPassword = false
                        viewModel.resetSuccessMessage = nil
                        viewModel.resetError = nil
                    }
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.gold)
                }
            }
        }
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
