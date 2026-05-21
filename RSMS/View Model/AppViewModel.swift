//
//  AppViewModel.swift
//  RSMS
//
//  Central app state using iOS 17+ Observation framework.
//

import SwiftUI

@Observable
class AppViewModel {
    var currentUser: UserProfile?
    var dataStore = DataStore()
    
    // Mock store ID for the current session since it's not wired to the auth user yet
    var currentStoreId: UUID? = UUID()

    func login(as role: UserRole) {
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
        }
    }
}
