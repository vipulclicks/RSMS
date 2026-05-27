//
//  ClientWishlistWorkspaceViewModel.swift
//  RSMS
//

import SwiftUI
import Observation

@Observable
@MainActor
final class ClientWishlistWorkspaceViewModel {
    
    let client: ClientProfile
    let dataStore: DataStore
    let associateId: UUID
    
    // UI States
    var productSearchQuery: String = ""
    var selectedProductForDetail: Product? = nil
    var selectedCategory: String? = nil
    var isLoading: Bool = false
    
    init(client: ClientProfile, dataStore: DataStore, associateId: UUID) {
        self.client = client
        self.dataStore = dataStore
        self.associateId = associateId
    }
    
    // MARK: - Computed Properties
    
    var clientName: String { client.fullName }
    
    var initials: String {
        client.fullName.split(separator: " ").prefix(2)
            .compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
    
    var isVIP: Bool {
        client.vipTier == .platinum || client.vipTier == .prive || client.vipTier == .gold
    }
    
    var vipBadgeText: String {
        client.vipTier.rawValue.uppercased()
    }
    
    var lastUpdatedFormatted: String {
        let dates = dataStore.wishlistItems.filter { $0.clientId == client.id }.map { $0.addedAt }
        guard let latest = dates.max() else { return "No items yet" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Updated " + formatter.string(from: latest)
    }
    
    var wishlistCount: Int {
        wishlistProducts.count
    }
    
    var estimatedWishlistValue: Double {
        wishlistProducts.reduce(0) { $0 + $1.price }
    }
    
    // All wishlist products for client (unfiltered)
    private var allWishlistProducts: [Product] {
        let items = dataStore.wishlistItems.filter { $0.clientId == client.id }
        return dataStore.products.filter { prod in
            items.contains { $0.productId == prod.id }
        }
    }
    
    // Resolving Products from Wishlist (filtered)
    var wishlistProducts: [Product] {
        var prods = allWishlistProducts
        
        if let selectedCategory {
            prods = prods.filter { $0.category == selectedCategory }
        }
        
        if !productSearchQuery.isEmpty {
            prods = prods.filter {
                $0.name.localizedCaseInsensitiveContains(productSearchQuery) ||
                $0.brand.localizedCaseInsensitiveContains(productSearchQuery)
            }
        }
        
        return prods
    }
    
    // Catalog Products not in wishlist (filtered)
    var availableCatalogProducts: [Product] {
        let wishlistIds = Set(allWishlistProducts.map { $0.id })
        var prods = dataStore.products.filter { !wishlistIds.contains($0.id) }
        
        if let selectedCategory {
            prods = prods.filter { $0.category == selectedCategory }
        }
        
        if !productSearchQuery.isEmpty {
            prods = prods.filter {
                $0.name.localizedCaseInsensitiveContains(productSearchQuery) ||
                $0.brand.localizedCaseInsensitiveContains(productSearchQuery)
            }
        }
        
        return prods
    }
    
    // Distinct product categories from available products
    var categories: [String] {
        let allProducts = allWishlistProducts + dataStore.products
        let cats = Set(allProducts.map { $0.category })
        return Array(cats).sorted()
    }
    
    // Extract dynamic preferences based on wishlist content
    var clientPreferences: [StylingChip] {
        var chips: [StylingChip] = []
        
        let brands = wishlistProducts.map { $0.brand }
        let brandCounts = brands.reduce(into: [:]) { $0[$1, default: 0] += 1 }
        if let topBrand = brandCounts.max(by: { $0.value < $1.value })?.key {
            chips.append(StylingChip(category: "Brand", value: topBrand, icon: "star.fill"))
        }
        
        let categories = wishlistProducts.map { $0.category }
        let catCounts = categories.reduce(into: [:]) { $0[$1, default: 0] += 1 }
        if let topCat = catCounts.max(by: { $0.value < $1.value })?.key {
            chips.append(StylingChip(category: "Category", value: topCat, icon: "tag.fill"))
        }
        
        if chips.isEmpty {
            chips.append(StylingChip(category: "Style", value: "Modern Luxury", icon: "sparkles"))
        }
        
        return chips
    }
    
    // MARK: - Actions
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await dataStore.fetchProducts()
            try await dataStore.fetchWishlistItems(clientId: client.id)
            try await dataStore.fetchCuratedCartsAndItems(forClient: client.id)
        } catch {
            print("[ClientWishlistWorkspaceViewModel] Error loading data: \(error)")
        }
    }
    
    func addToWishlist(product: Product) async {
        let item = WishlistItem(
            id: UUID(),
            clientId: client.id,
            productId: product.id,
            addedAt: Date(),
            isAvailable: product.isActive,
            notifyOnRestock: false,
            notes: nil
        )
        _ = try? await dataStore.createWishlistItem(item)
    }
    
    func removeFromWishlist(product: Product) async {
        if let item = dataStore.wishlistItems.first(where: { $0.clientId == client.id && $0.productId == product.id }) {
            _ = try? await dataStore.deleteWishlistItem(id: item.id)
        }
    }
    
    func moveToCuratedCart(product: Product) async {
        do {
            try await dataStore.addItemToCuratedCart(
                productId: product.id,
                price: product.price,
                forClient: client.id,
                associateId: associateId,
                note: "Moved from Wishlist"
            )
            // Remove from wishlist after successful move
            await removeFromWishlist(product: product)
        } catch {
            print("[ClientWishlistWorkspaceViewModel] Error moving to cart: \(error)")
        }
    }
    
    func createCartFromWishlist() async {
        let currentWishlistProducts = wishlistProducts
        
        for product in currentWishlistProducts {
            do {
                try await dataStore.addItemToCuratedCart(
                    productId: product.id,
                    price: product.price,
                    forClient: client.id,
                    associateId: associateId,
                    note: "Moved from Wishlist"
                )
                await removeFromWishlist(product: product)
            } catch {
                print("[ClientWishlistWorkspaceViewModel] Error adding \(product.name) to cart: \(error)")
            }
        }
    }
    
    func isProductAvailable(_ product: Product) -> Bool {
        return product.isActive
    }
}

struct StylingChip: Identifiable, Hashable {
    let id = UUID()
    let category: String
    let value: String
    let icon: String
}

extension ClientWishlistWorkspaceViewModel: Identifiable, Hashable {
    public var id: UUID { client.id }
    
    public static func == (lhs: ClientWishlistWorkspaceViewModel, rhs: ClientWishlistWorkspaceViewModel) -> Bool {
        lhs === rhs
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
