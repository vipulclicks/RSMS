//
//  ContentView.swift
//  RSMS
//
//  Created by Yashika Sharma on 19/05/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        Group {
            if let user = viewModel.currentUser {
                switch user.role {
                case .boutiqueManager:
                    BoutiqueManagerHomeView()
                case .salesAssociate:
                    SalesAssociateHomeView()
                case .inventoryController:
                    InventoryControllerHomeView()
                }
            } else {
                LoginView()
            }
        }
        .animation(.smooth(duration: 0.6), value: viewModel.currentUser != nil)
    }
}

#Preview("Boutique Manager Dashboard") {
    let vm = AppViewModel()
    vm.login(as: .boutiqueManager)
    return ContentView()
        .environment(vm)
        .environment(vm.dataStore)
}

#Preview("Sales Associate Dashboard") {
    let vm = AppViewModel()
    vm.login(as: .salesAssociate)
    return ContentView()
        .environment(vm)
        .environment(vm.dataStore)
}

#Preview("Inventory Dashboard") {
    let vm = AppViewModel()
    vm.login(as: .inventoryController)
    return ContentView()
        .environment(vm)
        .environment(vm.dataStore)
}

#Preview("Login Screen") {
    let vm = AppViewModel()
    return ContentView()
        .environment(vm)
        .environment(vm.dataStore)
}
