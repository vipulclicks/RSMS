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

    /// The store ID of the currently logged-in user.
    var currentStoreId: UUID? { currentUser?.storeId }

    // Tracks loading state for login
    var isAuthenticating = false
    var authError: String?

    /// Attempt to log in with real Supabase Auth credentials.
    func login(email: String, password: String) async {
        isAuthenticating = true
        authError = nil
        
        do {
            // 1. Get JWT from Supabase GoTrue
            let session = try await SupabaseAuth.shared.signIn(email: email, password: password)
            
            // 2. Set the global JWT so future DataStore requests bypass RLS
            SupabaseClient.shared.accessToken = session.accessToken
            
            // 3. Fetch the actual UserProfile row from the database
            let profile: UserProfile = try await dataStore.fetchUser(id: session.user.id)
            
            // 4. Update UI
            withAnimation(.spring(duration: 0.6)) {
                self.currentUser = profile
            }
        } catch {
            withAnimation {
                self.authError = error.localizedDescription
            }
        }
        
        isAuthenticating = false
    }

    func logout() {
        withAnimation(.smooth(duration: 0.4)) {
            currentUser = nil
            SupabaseClient.shared.accessToken = nil
        }
        dataStore.clearAllCaches()
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
