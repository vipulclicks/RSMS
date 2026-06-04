//
//  AppViewModel.swift
//  RSMS
//
//  Central app state using iOS 17+ Observation framework.
//  Holds the DataStore and current user session.
//

import SwiftUI

@Observable
@MainActor
class AppViewModel {
    let dataStore = DataStore()
    var currentUser: UserProfile?

    /// Base URL for remote checkout links (ngrok, public server, etc.)
    var customCheckoutBaseURL: String = (UserDefaults.standard.string(forKey: "custom_checkout_base_url") ?? "https://wttkl-152-57-76-254.run.pinggy-free.link").trimmingCharacters(in: .whitespacesAndNewlines) {
        didSet {
            let sanitized = customCheckoutBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            if customCheckoutBaseURL != sanitized {
                customCheckoutBaseURL = sanitized
            }
            UserDefaults.standard.set(sanitized, forKey: "custom_checkout_base_url")
        }
    }

    /// The store ID of the currently logged-in user.
    var currentStoreId: UUID? { currentUser?.storeId }

    // Tracks loading state for login
    var isAuthenticating = false
    var authError: String?

    // MFA state
    var mfaRequired = false
    var mfaFactorId: String?
    var isMFAVerifying = false
    var mfaError: String?
    var pendingSession: AuthSession?

    /// Attempt to log in with real Supabase Auth credentials.
    func login(email: String, password: String) async {
        isAuthenticating = true
        authError = nil
        
        do {
            // 1. Get JWT from Supabase GoTrue
            let session = try await SupabaseAuth.shared.signIn(email: email, password: password)
            
            // Check if user has MFA factors enrolled
            let factors = try await SupabaseMFA.shared.listFactors(accessToken: session.accessToken)
            let verifiedFactors = factors.filter { $0.status == "verified" }
            
            if let totpFactor = verifiedFactors.first(where: { $0.factorType == "totp" }) {
                // MFA required — park the session and show TOTP screen
                await MainActor.run {
                    withAnimation {
                        self.pendingSession = session
                        self.mfaFactorId = totpFactor.id
                        self.mfaRequired = true
                        self.isAuthenticating = false
                    }
                }
            } else {
                // No MFA — complete login normally
                await completeLogin(session: session)
            }
        } catch {
            withAnimation {
                self.authError = error.localizedDescription
                self.isAuthenticating = false
            }
        }
    }
    
    /// Verify MFA TOTP code and complete login
    func verifyMFA(code: String) async {
        guard let pendingSession = pendingSession, let factorId = mfaFactorId else { return }
        
        isMFAVerifying = true
        mfaError = nil
        
        do {
            // 1. Challenge
            let challenge = try await SupabaseMFA.shared.challenge(factorId: factorId, accessToken: pendingSession.accessToken)
            
            // 2. Verify
            let newSession = try await SupabaseMFA.shared.verify(factorId: factorId, challengeId: challenge.id, code: code, accessToken: pendingSession.accessToken)
            guard let newSession = newSession else { throw URLError(.badServerResponse) }
            
            // 3. Complete Login
            await completeLogin(session: newSession)
            
            await MainActor.run {
                self.mfaRequired = false
                self.pendingSession = nil
                self.mfaFactorId = nil
            }
        } catch {
            withAnimation {
                self.mfaError = "Invalid verification code. Please try again."
            }
        }
        
        isMFAVerifying = false
    }
    
    func cancelMFA() {
        withAnimation {
            mfaRequired = false
            pendingSession = nil
            mfaFactorId = nil
            mfaError = nil
        }
    }

    private func completeLogin(session: AuthSession) async {
        do {
            // 2. Set the global JWT so future DataStore requests bypass RLS
            SupabaseClient.shared.accessToken = session.accessToken
            
            // 3. Fetch the actual UserProfile row from the database
            let profile: UserProfile = try await dataStore.fetchUser(id: session.user.id)
            
            // 4. Update UI
            await MainActor.run {
                withAnimation(.spring(duration: 0.6)) {
                    self.currentUser = profile
                    self.isAuthenticating = false
                }
            }
        } catch {
            await MainActor.run {
                withAnimation {
                    self.authError = "Failed to load user profile: \(error.localizedDescription)"
                    self.isAuthenticating = false
                }
            }
        }
    }

    func logout() {
        withAnimation(.smooth(duration: 0.4)) {
            currentUser = nil
            SupabaseClient.shared.accessToken = nil
        }
        dataStore.clearAllCaches()
    }

    /// Development/Demo helper to instantly switch personas
    func demoSwitchRole(to newRole: UserRole) {
        guard let current = currentUser else { return }
        let updatedUser = UserProfile(
            id: current.id,
            email: current.email,
            fullName: current.fullName,
            role: newRole,
            storeId: current.storeId,
            avatarURL: current.avatarURL,
            phone: current.phone,
            isActive: current.isActive,
            createdAt: current.createdAt,
            updatedAt: current.updatedAt
        )
        withAnimation(.smooth(duration: 0.6)) {
            self.currentUser = updatedUser
        }
    }

    /// Re-fetch the current user's profile from Supabase and update `currentUser`.
    /// Call this on profile page appear to get the latest avatar URL and details.
    func refreshCurrentUser() async {
        guard let id = currentUser?.id else { return }
        do {
            let fresh: UserProfile = try await dataStore.fetchUser(id: id)
            await MainActor.run {
                withAnimation(.smooth(duration: 0.3)) {
                    self.currentUser = fresh
                }
            }
        } catch {
            print("[RSMS] refreshCurrentUser failed: \(error.localizedDescription)")
        }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - Password Reset (OTP Flow)
    // ══════════════════════════════════════════════════════════

    /// Tracks the current step of the reset-password flow.
    enum ResetStep {
        case enterEmail       // Step 1: user enters email
        case enterOTP         // Step 2: user enters the 6-digit code
        case enterNewPassword // Step 3: user enters a new password
        case success          // Done!
    }

    var resetStep: ResetStep = .enterEmail
    var isResettingPassword = false
    var resetSuccessMessage: String?
    var resetError: String?

    /// The email used for the current reset flow (needed for OTP verification).
    var resetEmail: String = ""

    /// Temporary access token obtained after OTP verification.
    private var resetAccessToken: String?

    /// Step 1: Send a 6-digit OTP code to the user's email.
    func requestPasswordReset(email: String) async {
        isResettingPassword = true
        resetError = nil
        resetSuccessMessage = nil
        resetEmail = email

        do {
            try await SupabaseAuth.shared.requestPasswordReset(email: email)
            withAnimation {
                resetSuccessMessage = "A 6-digit code has been sent to \(email). Check your inbox."
                resetStep = .enterOTP
            }
        } catch {
            withAnimation {
                resetError = error.localizedDescription
            }
        }

        isResettingPassword = false
    }

    /// Step 2: Verify the 6-digit OTP code. On success, stores the session token
    /// and advances to the new-password step.
    func verifyResetOTP(code: String) async {
        isResettingPassword = true
        resetError = nil
        resetSuccessMessage = nil

        do {
            let session = try await SupabaseAuth.shared.verifyOTP(email: resetEmail, otpCode: code)
            resetAccessToken = session.accessToken
            withAnimation {
                resetSuccessMessage = "Code verified! Enter your new password."
                resetStep = .enterNewPassword
            }
        } catch {
            withAnimation {
                resetError = error.localizedDescription
            }
        }

        isResettingPassword = false
    }

    /// Step 3: Update the password using the session token from OTP verification.
    func updatePassword(newPassword: String) async {
        guard let token = resetAccessToken else {
            withAnimation {
                resetError = "Session expired. Please restart the reset process."
            }
            return
        }

        isResettingPassword = true
        resetError = nil
        resetSuccessMessage = nil

        do {
            try await SupabaseAuth.shared.updatePassword(newPassword: newPassword, accessToken: token)
            withAnimation {
                resetSuccessMessage = "Password updated successfully! You can now sign in."
                resetStep = .success
            }
            resetAccessToken = nil
        } catch {
            withAnimation {
                resetError = error.localizedDescription
            }
        }

        isResettingPassword = false
    }

    /// Resets the password-reset flow back to the initial state.
    func clearResetState() {
        resetStep = .enterEmail
        isResettingPassword = false
        resetSuccessMessage = nil
        resetError = nil
        resetEmail = ""
        resetAccessToken = nil
    }
}
