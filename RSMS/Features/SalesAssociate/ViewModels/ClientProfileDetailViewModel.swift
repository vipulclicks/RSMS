//
//  ClientProfileDetailViewModel.swift
//  RSMS
//
//  ViewModel for the Client Profile Detail screen.
//  Provides client data, related records, and formatting helpers.
//

import SwiftUI

@Observable
final class ClientProfileDetailViewModel {

    // MARK: - Data
    let client: ClientProfile
    let dataStore: DataStore

    init(client: ClientProfile, dataStore: DataStore) {
        self.client = client
        self.dataStore = dataStore
    }

    // MARK: - Computed

    var initials: String {
        client.fullName.split(separator: " ").prefix(2)
            .compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    var clientWishlist: [WishlistItem] {
        dataStore.wishlistItems.filter { $0.clientId == client.id }
    }

    var clientAnniversaries: [ClientAnniversary] {
        dataStore.clientAnniversaries.filter { $0.clientId == client.id }
    }

    var clientRecommendations: [AIRecommendation] {
        dataStore.aiRecommendations.filter { $0.clientId == client.id }
    }

    var clientTransactions: [Transaction] {
        dataStore.transactions.filter { $0.clientId == client.id }
    }

    var lifetimeValue: Double {
        clientTransactions
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.totalAmount }
    }

    var lifetimeValueFormatted: String {
        "€\(Int(lifetimeValue).formatted())"
    }

    // MARK: - Size Preferences (non-nil fields)

    var sizePreferences: [(label: String, value: String)] {
        var result: [(String, String)] = []
        if let v = client.shoeSize       { result.append(("Shoe Size", v)) }
        if let v = client.ringSize       { result.append(("Ring Size", v)) }
        if let v = client.braceletSize   { result.append(("Bracelet", v)) }
        if let v = client.necklaceLength { result.append(("Necklace", v)) }
        if let v = client.wristSize      { result.append(("Wrist", v)) }
        if let v = client.beltSize       { result.append(("Belt", v)) }
        return result
    }

    // MARK: - Detailed Preferences (non-nil fields)

    var detailedPreferences: [(label: String, value: String)] {
        var result: [(String, String)] = []
        if let v = client.preferredMetal           { result.append(("Metal", v)) }
        if let v = client.preferredGemstone        { result.append(("Gemstone", v)) }
        if let v = client.watchCasePreference      { result.append(("Watch Case", v)) }
        if let v = client.strapMaterialPreference  { result.append(("Strap", v)) }
        if let v = client.preferredBagSize         { result.append(("Bag Size", v)) }
        if let v = client.preferredBagStyle        { result.append(("Bag Style", v)) }
        if let v = client.fragranceFamily          { result.append(("Fragrance", v)) }
        if let v = client.fragranceStrength        { result.append(("Strength", v)) }
        if let v = client.stylePreference          { result.append(("Style", v)) }
        if let v = client.shoppingPreference       { result.append(("Shopping", v)) }
        return result
    }

    // MARK: - Actions

    func addToWishlist(productId: UUID, notes: String?) async {
        let wish = WishlistItem(
            id: UUID(),
            clientId: client.id,
            productId: productId,
            addedAt: Date(),
            isAvailable: true,
            notifyOnRestock: true,
            notes: notes?.isEmpty == false ? notes : nil
        )
        do {
            try await dataStore.createWishlistItem(wish)
        } catch {
            print("Wishlist addition failed. Saving to local cache: \(error.localizedDescription)")
            dataStore.wishlistItems.append(wish)
        }
    }

    func removeFromWishlist(itemId: UUID) async {
        do {
            try await dataStore.deleteWishlistItem(id: itemId)
        } catch {
            print("Wishlist deletion failed. Removing from local cache: \(error.localizedDescription)")
            dataStore.wishlistItems.removeAll { $0.id == itemId }
        }
    }

    // MARK: - Formatting

    func tierColor(_ tier: VIPTier) -> Color {
        switch tier {
        case .standard: return RSMSTheme.textSecondary
        case .silver:   return Color(red: 192/255, green: 192/255, blue: 192/255)
        case .gold:     return RSMSTheme.primary
        case .platinum: return Color(red: 176/255, green: 196/255, blue: 222/255)
        case .prive:    return RSMSTheme.danger
        }
    }

    func productName(for id: UUID) -> String {
        dataStore.products.first { $0.id == id }?.name ?? "Unknown Product"
    }

    func confidenceText(_ value: Double) -> String {
        "\(Int(value * 100))%"
    }

    func recommendationTypeLabel(_ type: RecommendationType) -> String {
        switch type {
        case .crossSell: return "Cross-Sell"
        case .upSell:    return "Up-Sell"
        case .similar:   return "Similar"
        case .trending:  return "Trending"
        }
    }

    func transactionStatusColor(_ status: TransactionStatus) -> Color {
        switch status {
        case .pending:   return RSMSTheme.warning
        case .completed: return RSMSTheme.success
        case .voided:    return RSMSTheme.danger
        case .refunded:  return RSMSTheme.info
        }
    }
}
