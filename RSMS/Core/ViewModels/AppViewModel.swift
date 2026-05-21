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
    var dataStore = DataStore()
    
    // Mock store ID for the current session since it's not wired to the auth user yet
    var currentStoreId: UUID? = UUID()

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
}
