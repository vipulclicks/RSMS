import SwiftUI

// Catalog tab now routes directly to ProductLookupView.
// Auth Certificate generation is contextually available from
// the Product Detail Sheet inside Product Lookup.
struct CatalogHubView: View {
    var body: some View {
        ProductLookupView()
    }
}
