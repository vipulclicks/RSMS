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
