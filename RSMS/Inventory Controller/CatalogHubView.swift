import SwiftUI

struct CatalogHubView: View {
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                HubNavigationCard(
                    title: "Product Lookup & Stock In",
                    icon: "magnifyingglass.circle.fill",
                    color: RSMSTheme.primaryDark,
                    destination: ProductLookupView()
                )
                
                HubNavigationCard(
                    title: "Auth Certificates",
                    icon: "seal.fill",
                    color: RSMSTheme.gold,
                    destination: AuthCertificateGeneratorView()
                )
            }
            .padding(24)
        }
        .background(RSMSTheme.background)
        .navigationTitle("Catalog")
        .navigationBarTitleDisplayMode(.inline)
    }
}
