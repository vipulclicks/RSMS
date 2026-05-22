//
//  AppViewModel.swift
//  RSMS
//
//  Central app state using iOS 17+ Observation framework.
//  Holds the DataStore and current user session.
//

import SwiftUI

@Observable
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

    func login(as role: UserRole) {
        // Fallback for seamless demo testing if desired.
        // In a real flow, this would call login(email:password:) with hardcoded test accounts.
        switch role {
        case .boutiqueManager:
            currentUser = .previewManager
        case .salesAssociate:
            currentUser = .previewAssociate
        case .inventoryController:
            currentUser = .previewInventory
        }
    }

    func logout() {
        withAnimation(.smooth(duration: 0.4)) {
            currentUser = nil
            SupabaseClient.shared.accessToken = nil
        }
    }

    // ══════════════════════════════════════════════════════════
    // MARK: - Password Reset
    // ══════════════════════════════════════════════════════════

    /// Tracks whether a reset-password request is in progress.
    var isResettingPassword = false
    /// Success message after reset email is sent.
    var resetSuccessMessage: String?
    /// Error message if reset fails.
    var resetError: String?

    /// Step 1: Request a password-reset email.
    /// Call this from a "Forgot Password" screen.
    /// On success, sets `resetSuccessMessage`; on failure, sets `resetError`.
    func requestPasswordReset(email: String) async {
        isResettingPassword = true
        resetError = nil
        resetSuccessMessage = nil

        do {
            try await SupabaseAuth.shared.requestPasswordReset(email: email)
            withAnimation {
                resetSuccessMessage = "A password reset link has been sent to \(email). Please check your inbox."
            }
        } catch {
            withAnimation {
                resetError = error.localizedDescription
            }
        }

        isResettingPassword = false
    }

    /// Step 2: Update the password using a valid session token.
    /// Call this after the user taps the reset link and the app receives the token.
    func updatePassword(newPassword: String) async {
        guard let token = SupabaseClient.shared.accessToken else {
            withAnimation {
                resetError = "No active session. Please use the reset link from your email first."
            }
            return
        }

        isResettingPassword = true
        resetError = nil
        resetSuccessMessage = nil

        do {
            try await SupabaseAuth.shared.updatePassword(newPassword: newPassword, accessToken: token)
            withAnimation {
                resetSuccessMessage = "Password updated successfully. Please log in with your new password."
            }
        } catch {
            withAnimation {
                resetError = error.localizedDescription
            }
        }

        isResettingPassword = false
    }
}
