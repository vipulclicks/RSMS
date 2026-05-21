//
//  ContentView.swift
//  RSMS
//
//  Created by Yashika Sharma on 19/05/26.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = AppViewModel()
    
    var body: some View {
        Group {
            if let user = viewModel.currentUser {
                switch user.role {
                case .inventoryController:
                    InventoryControllerHomeView()
                case .boutiqueManager:
                    Text("Boutique Manager Dashboard") // Placeholder for future views
                case .salesAssociate:
                    Text("Sales Associate Dashboard") // Placeholder for future views
                }
            } else {
                LoginView()
            }
        }
        .environment(viewModel)
    }
}

#Preview {
    ContentView()
}
