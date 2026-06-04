import SwiftUI

struct MovementsHubView: View {
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                HubNavigationCard(
                    title: "Store Transfers",
                    icon: "arrow.left.arrow.right",
                    color: RSMSTheme.gold,
                    destination: InventoryTransferView()
                )
                
                HubNavigationCard(
                    title: "Vendor Returns",
                    icon: "arrow.uturn.backward.circle.fill",
                    color: RSMSTheme.warning,
                    destination: VendorReturnView()
                )
                
                HubNavigationCard(
                    title: "Returns and Exchanges",
                    icon: "arrow.uturn.backward.circle.fill",
                    color: RSMSTheme.primary,
                    destination: InspectionQueueView()
                )
                
                HubNavigationCard(
                    title: "Service Center",
                    icon: "wrench.and.screwdriver.fill",
                    color: RSMSTheme.info,
                    destination: ServiceCenterTrackingView()
                )
            }
            .padding(24)
        }
        .background(RSMSTheme.background)
        .navigationTitle("Movements")
        .navigationBarTitleDisplayMode(.inline)
    }
}
