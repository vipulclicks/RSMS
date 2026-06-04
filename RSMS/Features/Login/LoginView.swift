//
//  LoginView.swift
//  RSMS
//
//  Luxury role-selection login screen.
//

import SwiftUI

struct LoginView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
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

    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        ZStack {
            // Background
            RSMSTheme.background.ignoresSafeArea()
            backgroundDecoration

            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: isCompact ? 40 : 80)

                        // Branding
                        brandingSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : -20)

                        Spacer().frame(height: isCompact ? 40 : 60)

                        // Login Form
                        loginForm
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)

                        Spacer(minLength: isCompact ? 40 : 80)

                        // Store info
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                            Text("Mysore Karnataka, India")
                        }
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.textTertiary)
                        .padding(.bottom, isCompact ? 16 : 30)
                        .opacity(appeared ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }
        }
    }

    // MARK: - Branding

    private var brandingSection: some View {
        VStack(spacing: 12) {
            // Diamond icon
            Image(systemName: "diamond.fill")
                .font(.largeTitle)
                .foregroundStyle(RSMSTheme.goldGradient)

            Text("Luxora")
                .font(.largeTitle.weight(.light))
                .tracking(isCompact ? 6 : 8)
                .foregroundStyle(RSMSTheme.goldGradient)

            Rectangle()
                .fill(RSMSTheme.goldGradient)
                .frame(width: isCompact ? 40 : 60, height: 1)

            Text("Retail Store Management")
                .font(.caption.weight(.medium))
                .tracking(isCompact ? 3 : 4)
                .foregroundStyle(RSMSTheme.textSecondary)
                .textCase(.uppercase)
        }
    }

    // MARK: - Login Form

    private var loginForm: some View {
        VStack(spacing: isCompact ? 20 : 24) {
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RSMSTheme.danger.opacity(0.1))
                .cornerRadius(8)
            }
            
            VStack(spacing: isCompact ? 12 : 16) {
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
                        .font(.body)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 50)
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
                        .font(.body)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 50)
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
            .padding(.top, -4)

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
                            .font(.headline.weight(.semibold))
                    }
                    Spacer()
                }
                .frame(minHeight: 50)
                .background(RSMSTheme.goldGradient)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: RSMSTheme.gold.opacity(0.3), radius: isCompact ? 6 : 10, y: 4)
            }
            .disabled(email.isEmpty || password.isEmpty || viewModel.isAuthenticating)
            .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
            .padding(.top, 4)
        }
        .padding(isCompact ? 24 : 32)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 20 : 24)
                .fill(RSMSTheme.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: isCompact ? 20 : 24)
                        .stroke(RSMSTheme.gold.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: isCompact ? 20 : 30, y: isCompact ? 10 : 15)
        .frame(maxWidth: 400)
        .padding(.horizontal, isCompact ? 24 : 0)
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
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Step icon
                    stepIcon
                        .padding(.top, 32)

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

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, isCompact ? 16 : 32)
                .frame(maxWidth: 440)
                .frame(maxWidth: .infinity) // Center the 440pt content
            }
            .background(RSMSTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
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
        .font(.largeTitle)
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RSMSTheme.success.opacity(0.1))
                .cornerRadius(8)
            }

            if let error = viewModel.resetError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(RSMSTheme.danger)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RSMSTheme.danger.opacity(0.1))
                .cornerRadius(8)
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
                    .font(.body)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 50)
            .background(RSMSTheme.surfaceSecondary)
            .cornerRadius(12)

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
                    .font(.body)
                    .onChange(of: otpCode) { _, newValue in
                        otpCode = String(newValue.filter { $0.isNumber }.prefix(10))
                    }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 50)
            .background(RSMSTheme.surfaceSecondary)
            .cornerRadius(12)

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
            .padding(.top, 4)
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
                    .font(.body)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 50)
            .background(RSMSTheme.surfaceSecondary)
            .cornerRadius(12)

            HStack {
                Image(systemName: "lock.rotation")
                    .foregroundStyle(RSMSTheme.gold)
                    .frame(width: 24)
                SecureField("Confirm Password", text: $confirmPassword)
                    .foregroundStyle(RSMSTheme.textPrimary)
                    .font(.body)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 50)
            .background(RSMSTheme.surfaceSecondary)
            .cornerRadius(12)

            // Password mismatch warning
            if !confirmPassword.isEmpty && newPassword != confirmPassword {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text("Passwords do not match")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(RSMSTheme.danger)
                .frame(maxWidth: .infinity, alignment: .leading)
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
        VStack(spacing: 24) {
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
                        .font(.headline.weight(.semibold))
                    Spacer()
                }
                .frame(minHeight: 50)
                .background(RSMSTheme.goldGradient)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
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
                        .font(.headline.weight(.semibold))
                }
                Spacer()
            }
            .frame(minHeight: 50)
            .background(RSMSTheme.goldGradient)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(disabled || viewModel.isResettingPassword)
        .opacity(disabled ? 0.6 : 1.0)
    }

    // MARK: - Background Decoration

    private var backgroundDecoration: some View {
        ZStack {
            Circle()
                .fill(RSMSTheme.gold.opacity(0.04))
                .frame(width: isCompact ? 400 : 600, height: isCompact ? 400 : 600)
                .offset(x: isCompact ? -150 : -200, y: isCompact ? -200 : -300)
            Circle()
                .fill(RSMSTheme.gold.opacity(0.03))
                .frame(width: isCompact ? 300 : 400, height: isCompact ? 300 : 400)
                .offset(x: isCompact ? 150 : 300, y: isCompact ? 150 : 200)
        }
    }
}

#Preview {
    LoginView()
        .environment(AppViewModel())
}
