//
//  ClientelingViewModel.swift
//  RSMS
//
//  ViewModel for the Clienteling & CRM screen.
//  CRUD for client profiles, anniversaries, and wishlists.
//

import SwiftUI

@Observable
final class ClientelingViewModel {

    private let dataStore: DataStore
    private let associateId: UUID

    var searchQuery = ""
    var selectedTier: VIPTier? = nil
    var isLoading = false
    var errorMessage: String?

    init(dataStore: DataStore, associateId: UUID) {
        self.dataStore   = dataStore
        self.associateId = associateId
    }

    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchClients()
            try await dataStore.fetchClientAnniversaries()
            try await dataStore.fetchWishlistItems()
            try await dataStore.fetchProducts()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Clients
    var allClients: [ClientProfile] { dataStore.clients }

    var filteredClients: [ClientProfile] {
        var result = allClients
        if let tier = selectedTier { result = result.filter { $0.vipTier == tier } }
        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            result = result.filter {
                $0.fullName.lowercased().contains(q) ||
                ($0.email?.lowercased().contains(q) ?? false) ||
                ($0.phone?.contains(q) ?? false)
            }
        }
        result.sort { tierWeight($0.vipTier) > tierWeight($1.vipTier) }
        return result
    }

    func createClient(_ client: ClientProfile) async throws {
        try await dataStore.createClient(client)
    }

    func updateClient(_ client: ClientProfile) async throws {
        try await dataStore.updateClient(client)
    }

    func deleteClient(id: UUID) async throws {
        try await dataStore.deleteClient(id: id)
    }

    // MARK: - Anniversaries
    func anniversaries(for clientId: UUID) -> [ClientAnniversary] {
        dataStore.clientAnniversaries.filter { $0.clientId == clientId }.sorted { $0.date < $1.date }
    }

    func createAnniversary(_ a: ClientAnniversary) async throws {
        try await dataStore.createClientAnniversary(a)
    }

    func deleteAnniversary(id: UUID) async throws {
        try await dataStore.deleteClientAnniversary(id: id)
    }

    // MARK: - Wishlist
    func wishlist(for clientId: UUID) -> [WishlistItem] {
        dataStore.wishlistItems.filter { $0.clientId == clientId }
    }

    func addToWishlist(_ item: WishlistItem) async throws {
        try await dataStore.createWishlistItem(item)
    }

    func removeFromWishlist(id: UUID) async throws {
        try await dataStore.deleteWishlistItem(id: id)
    }

    // MARK: - Helpers
    func productName(for id: UUID) -> String { dataStore.productName(for: id) }

    private func tierWeight(_ tier: VIPTier) -> Int {
        switch tier {
        case .standard: return 1; case .silver: return 2; case .gold: return 3
        case .platinum: return 4; case .prive: return 5
        }
    }

    func tierColor(_ tier: VIPTier) -> Color {
        switch tier {
        case .standard: return RSMSTheme.textSecondary
        case .silver:   return RSMSTheme.info
        case .gold:     return RSMSTheme.gold
        case .platinum: return RSMSTheme.success
        case .prive:    return RSMSTheme.danger
        }
    }
}
