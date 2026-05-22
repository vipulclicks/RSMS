
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
#Preview {
    ContentView()
    .environment(AppViewModel())}
