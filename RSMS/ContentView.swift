//
//  ContentView.swift
//  RSMS
//
//  Main Application Router
//

import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        Group {
            if let user = appVM.currentUser {
                // Route to the appropriate dashboard based on Role
                switch user.role {
                case .boutiqueManager:
                    BoutiqueManagerHomeView()
                case .salesAssociate:
                    SalesAssociateHomeView()
                case .inventoryController:
                    InventoryControllerHomeView()
                }
            } else {
                // Not logged in -> Show Login
                LoginView()
            }
        }
        .animation(.default, value: appVM.currentUser != nil)
    }
}

#Preview {
    ContentView()
        .environment(AppViewModel())
}
