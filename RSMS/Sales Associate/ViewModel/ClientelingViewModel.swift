//
//  ClientelingViewModel.swift
//  RSMS
//
//  Fetches live client, anniversary, wishlist and product data from Supabase.
//  Replaces hardcoded preview data.
//

import SwiftUI

@Observable
final class ClientelingViewModel {

    // MARK: - State
    private(set) var clients: [ClientProfile] = []
    private(set) var anniversaries: [ClientAnniversary] = []
    private(set) var wishlistItems: [WishlistItem] = []
    private(set) var products: [Product] = []
    var isLoading = false
    var errorMessage: String? = nil

    // MARK: - Convenience (first client in list — kept for single-client views)
    var client: ClientProfile? { clients.first }
    var anniversary: ClientAnniversary? { anniversaries.first }
    var wishlist: WishlistItem? { wishlistItems.first }

    var wishlistProduct: Product? {
        guard let wl = wishlist else { return nil }
        return products.first(where: { $0.id == wl.productId })
    }

    // MARK: - Load

    @MainActor
    func load(dataStore: DataStore, clientId: UUID? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await dataStore.fetchClients() }
                group.addTask { try await dataStore.fetchClientAnniversaries(clientId: clientId) }
                group.addTask { try await dataStore.fetchWishlistItems(clientId: clientId) }
                group.addTask { try await dataStore.fetchProducts() }
                try await group.waitForAll()
            }

            clients = clientId == nil
                ? dataStore.clients
                : dataStore.clients.filter { $0.id == clientId }
            anniversaries = clientId == nil
                ? dataStore.clientAnniversaries
                : dataStore.clientAnniversaries.filter { $0.clientId == clientId }
            wishlistItems = clientId == nil
                ? dataStore.wishlistItems
                : dataStore.wishlistItems.filter { $0.clientId == clientId }
            products = dataStore.products
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Formatting

    func formattedDate(_ date: Date) -> String {
        RSMSDateFormatter.dayMonth.string(from: date)
    }

    func tierColor(_ tier: VIPTier) -> Color {
        switch tier {
        case .standard: return RSMSTheme.textSecondary
        case .silver:   return Color(red: 192/255, green: 192/255, blue: 192/255)
        case .gold:     return RSMSTheme.primary
        case .platinum: return Color(red: 176/255, green: 196/255, blue: 222/255)
        case .prive:    return RSMSTheme.danger
        case .vip:      return RSMSTheme.primaryDark
        }
    }
}
