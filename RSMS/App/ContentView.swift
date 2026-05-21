
import SwiftUI

struct ContentView: View {
<<<<<<< HEAD:RSMS/ContentView.swift
    @State private var viewModel = AppViewModel()
    
=======
    @Environment(AppViewModel.self) private var viewModel

>>>>>>> develop:RSMS/App/ContentView.swift
    var body: some View {
        Group {
            if let user = viewModel.currentUser {
                switch user.role {
<<<<<<< HEAD:RSMS/ContentView.swift
                case .inventoryController:
                    InventoryControllerHomeView()
                case .boutiqueManager:
                    Text("Boutique Manager Dashboard") // Placeholder for future views
                case .salesAssociate:
                    Text("Sales Associate Dashboard") // Placeholder for future views
=======
                case .boutiqueManager:
                    BoutiqueManagerHomeView()
                case .salesAssociate:
                    SalesAssociateHomeView()
                case .inventoryController:
                    InventoryControllerHomeView()
>>>>>>> develop:RSMS/App/ContentView.swift
                }
            } else {
                LoginView()
            }
        }
<<<<<<< HEAD:RSMS/ContentView.swift
        .environment(viewModel)
=======
        .animation(.smooth(duration: 0.6), value: viewModel.currentUser != nil)
>>>>>>> develop:RSMS/App/ContentView.swift
    }
}
#Preview {
    ContentView()
        .environment(AppViewModel())
}
