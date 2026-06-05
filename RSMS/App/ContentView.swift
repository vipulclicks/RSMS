import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var showGlobalSplash = true

    var body: some View {
        ZStack {
            if viewModel.mfaRequired {
                MFAVerificationView()
                    .transition(.opacity)
            } else if let user = viewModel.currentUser {
                // User is authenticated - Show Home View AFTER splash
                if !showGlobalSplash {
                    Group {
                        switch user.role {
                        case .boutiqueManager:
                            BoutiqueManagerHomeView()
                        case .salesAssociate:
                            SalesAssociateHomeView()
                        case .inventoryController:
                            InventoryControllerHomeView()
                        case .client:
                            ClientPortalView()
                        }
                    }
                    .transition(.opacity)
                }
                
                // Show Splash overlay while loading authenticated state
                if showGlobalSplash {
                    LuxoraSplashScreen()
                        .transition(.opacity)
                        .zIndex(1)
                }
            } else {
                // User is NOT authenticated - Let LoginView handle its own seamless slide-up splash animation natively!
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.8), value: showGlobalSplash)
        .animation(.smooth(duration: 0.6), value: viewModel.currentUser != nil)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showGlobalSplash = false
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppViewModel())
}
