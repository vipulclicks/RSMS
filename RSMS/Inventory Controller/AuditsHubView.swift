import SwiftUI

struct AuditsHubView: View {
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                HubNavigationCard(
                    title: "Cycle Counts",
                    icon: "arrow.triangle.2.circlepath",
                    color: RSMSTheme.success,
                    destination: CycleCountView()
                )
                
                HubNavigationCard(
                    title: "Audit & Reconcile",
                    icon: "doc.text.magnifyingglass",
                    color: RSMSTheme.danger,
                    destination: StockReconciliationView()
                )
                
                HubNavigationCard(
                    title: "Audit Trail",
                    icon: "list.bullet.rectangle.portrait.fill",
                    color: RSMSTheme.info,
                    destination: AuditTrailView()
                )
            }
            .padding(24)
        }
        .background(RSMSTheme.background)
        .navigationTitle("Audits & Counts")
        .navigationBarTitleDisplayMode(.inline)
    }
}
