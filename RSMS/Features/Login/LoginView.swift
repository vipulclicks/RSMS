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
    @State private var otpCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

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
                    Text("Mysore Karnataka, India")
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

            Text("Luxora")
                .font(.system(size: 36, weight: .light))
                .tracking(8)
                .foregroundStyle(RSMSTheme.goldGradient)

            Rectangle()
                .fill(RSMSTheme.goldGradient)
                .frame(width: 60, height: 1)

            Text("Retail Store Management")
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
        .padding(.horizontal, 24)
        .sheet(isPresented: $showForgotPassword, onDismiss: {
            viewModel.clearResetState()
            otpCode = ""
            newPassword = ""
            confirmPassword = ""
        }) {
            forgotPasswordSheet
        }
    }

    // MARK: - Forgot Password Sheet (3-Step OTP Flow)

    private var forgotPasswordSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Step icon
                stepIcon
                    .padding(.top, 20)

                // Step title & subtitle
                stepHeader

                // Messages (success / error)
                feedbackMessages

                // Step-specific content
                switch viewModel.resetStep {
                case .enterEmail:
                    emailStepContent
                case .enterOTP:
                    otpStepContent
                case .enterNewPassword:
                    newPasswordStepContent
                case .success:
                    successStepContent
                }

                Spacer()
            }
            .padding()
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        showForgotPassword = false
                    }
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.gold)
                }
            }
        }
    }

    // MARK: - Step Icon

    private var stepIcon: some View {
        Group {
            switch viewModel.resetStep {
            case .enterEmail:
                Image(systemName: "envelope.badge.fill")
            case .enterOTP:
                Image(systemName: "lock.shield.fill")
            case .enterNewPassword:
                Image(systemName: "key.fill")
            case .success:
                Image(systemName: "checkmark.seal.fill")
            }
        }
        .font(.system(size: 48))
        .foregroundStyle(RSMSTheme.goldGradient)
    }

    // MARK: - Step Header

    private var stepHeader: some View {
        VStack(spacing: 8) {
            switch viewModel.resetStep {
            case .enterEmail:
                Text("Reset Your Password")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("Enter your email and we'll send you a 6-digit code.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .multilineTextAlignment(.center)
            case .enterOTP:
                Text("Enter Verification Code")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("We sent a 6-digit code to **\(viewModel.resetEmail)**")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .multilineTextAlignment(.center)
            case .enterNewPassword:
                Text("Set New Password")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(RSMSTheme.textPrimary)
                Text("Choose a strong password (minimum 6 characters).")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.textSecondary)
                    .multilineTextAlignment(.center)
            case .success:
                Text("Password Updated!")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(RSMSTheme.success)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Feedback Messages

    private var feedbackMessages: some View {
        VStack(spacing: 8) {
            if let success = viewModel.resetSuccessMessage, viewModel.resetStep != .success {
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
        }
    }

    // MARK: - Step 1: Enter Email

    private var emailStepContent: some View {
        VStack(spacing: 16) {
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

            resetActionButton(title: "Send Code", disabled: resetEmail.isEmpty) {
                await viewModel.requestPasswordReset(email: resetEmail)
            }
        }
    }

    // MARK: - Step 2: Enter OTP

    private var otpStepContent: some View {
        VStack(spacing: 16) {
            // OTP Code field
            HStack {
                Image(systemName: "number")
                    .foregroundStyle(RSMSTheme.gold)
                    .frame(width: 24)
                TextField("6-Digit Code", text: $otpCode)
                    .keyboardType(.numberPad)
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .onChange(of: otpCode) { _, newValue in
                        // Allow up to 10 digits to be safe
                        otpCode = String(newValue.filter { $0.isNumber }.prefix(10))
                    }
            }
            .padding()
            .background(RSMSTheme.surfaceSecondary)
            .cornerRadius(12)
            .padding(.horizontal)

            resetActionButton(title: "Verify Code", disabled: otpCode.count < 6) {
                await viewModel.verifyResetOTP(code: otpCode)
            }

            // Resend option
            Button {
                Task {
                    await viewModel.requestPasswordReset(email: resetEmail)
                }
            } label: {
                Text("Didn't get the code? Resend")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RSMSTheme.gold)
            }
        }
    }

    // MARK: - Step 3: New Password

    private var newPasswordStepContent: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundStyle(RSMSTheme.gold)
                    .frame(width: 24)
                SecureField("New Password", text: $newPassword)
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            .padding()
            .background(RSMSTheme.surfaceSecondary)
            .cornerRadius(12)
            .padding(.horizontal)

            HStack {
                Image(systemName: "lock.rotation")
                    .foregroundStyle(RSMSTheme.gold)
                    .frame(width: 24)
                SecureField("Confirm Password", text: $confirmPassword)
                    .foregroundStyle(RSMSTheme.textPrimary)
            }
            .padding()
            .background(RSMSTheme.surfaceSecondary)
            .cornerRadius(12)
            .padding(.horizontal)

            // Password mismatch warning
            if !confirmPassword.isEmpty && newPassword != confirmPassword {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text("Passwords do not match")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(RSMSTheme.danger)
                .padding(.horizontal)
            }

            resetActionButton(
                title: "Update Password",
                disabled: newPassword.count < 6 || newPassword != confirmPassword
            ) {
                await viewModel.updatePassword(newPassword: newPassword)
            }
        }
    }

    // MARK: - Step 4: Success

    private var successStepContent: some View {
        VStack(spacing: 20) {
            Text("Your password has been updated successfully. You can now sign in with your new password.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showForgotPassword = false
            } label: {
                HStack {
                    Spacer()
                    Text("Back to Sign In")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                .background(RSMSTheme.goldGradient)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Reusable Action Button

    private func resetActionButton(title: String, disabled: Bool, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack {
                Spacer()
                if viewModel.isResettingPassword {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.headline)
                }
                Spacer()
            }
            .padding()
            .background(RSMSTheme.goldGradient)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(disabled || viewModel.isResettingPassword)
        .opacity(disabled ? 0.6 : 1.0)
        .padding(.horizontal)
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
