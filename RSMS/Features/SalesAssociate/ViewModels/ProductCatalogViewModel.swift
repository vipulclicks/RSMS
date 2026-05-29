//
//  ProductCatalogViewModel.swift
//  RSMS
//
//  ViewModel for the Sales Associate Product Catalog.
//  Fetches products and stock items from Supabase via DataStore,
//  drives search, category/collection/price/stock filters,
//  and maintains a transient cart selection for curated carts.
//

import SwiftUI
import Observation

enum ClientReaction: String, CaseIterable, Identifiable, Hashable {
    case shortlisted = "Shortlisted"
    case maybe = "Maybe"
    case passed = "Not Interested"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .shortlisted: return .green
        case .maybe: return .orange
        case .passed: return .red
        }
    }
}

struct CartSelectionItem: Identifiable, Hashable {
    let id: UUID
    let product: Product
    var quantity: Int = 1
    var reaction: ClientReaction? = nil
    var saNote: String = ""
    
    var productId: UUID { product.id }
    
    static func == (lhs: CartSelectionItem, rhs: CartSelectionItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - ProductCatalogViewModel

@Observable
final class ProductCatalogViewModel {

    // ── Dependencies ──────────────────────────────────────────
    private let dataStore: DataStore
    private let storeId: UUID?

    // ── Active Client Context ──────────────────────────────────
    var activeClient: ClientProfile?
    var filterByClientSizes = false
    var highlightPreferences = true
    var associateId: UUID?

    // ── State ─────────────────────────────────────────────────
    var isLoading = false
    var errorMessage: String?
    var isSaving = false
    var showSuccess = false
    
    var client: ClientProfile {
        return activeClient ?? .preview // Fallback just in case, though activeClient should be non-nil
    }

    // ── Filter State ──────────────────────────────────────────
    var searchQuery = ""
    var selectedCategory: String?
    var selectedCollection: String?
    var showInStockOnly = false

    // Price range (driven by slider; initialised to 0...maxPriceSliderBound)
    var minPrice: Double = 0
    var maxPrice: Double = 0
    private(set) var maxPriceSliderBound: Double = 100_000

    var totalValue: Double {
        cartItems.reduce(0) { $0 + ($1.product.price * Double($1.quantity)) }
    }

    // ── Derived ───────────────────────────────────────────────
    var availableCategories: [String] {
        Array(Set(dataStore.products.filter(\.isActive).map(\.category))).sorted()
    }

    var availableCollections: [String] {
        dataStore.products
            .filter(\.isActive)
            .compactMap(\.collection)
            .reduce(into: [String]()) { result, col in
                if !result.contains(col) { result.append(col) }
            }
            .sorted()
    }

    var filteredProducts: [Product] {
        var results = dataStore.products.filter(\.isActive)

        // Sizing auto-filter if enabled and client matches
        if filterByClientSizes, activeClient != nil {
            results = results.filter { isSizeMatch(for: $0) }
        }

        // Category
        if let cat = selectedCategory {
            results = results.filter { $0.category == cat }
        }

        // Collection
        if let col = selectedCollection {
            results = results.filter { $0.collection == col }
        }

        // Search
        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            results = results.filter {
                $0.name.lowercased().contains(q) ||
                $0.sku.lowercased().contains(q) ||
                $0.brand.lowercased().contains(q) ||
                ($0.collection?.lowercased().contains(q) ?? false)
            }
        }

        // Price range (only if user moved the slider away from defaults)
        if maxPrice > 0 && maxPrice < maxPriceSliderBound {
            results = results.filter { $0.price <= maxPrice }
        }
        if minPrice > 0 {
            results = results.filter { $0.price >= minPrice }
        }

        // Stock availability
        if showInStockOnly {
            results = results.filter { stockQuantity(for: $0.id) > 0 }
        }

        // Elevate matches if preferences highlighted
        if highlightPreferences, let client = activeClient {
            results.sort { p1, p2 in
                let p1Match = hasPreferenceMatch(for: p1, client: client)
                let p2Match = hasPreferenceMatch(for: p2, client: client)
                if p1Match != p2Match {
                    return p1Match && !p2Match
                }
                return p1.name < p2.name
            }
        } else {
            results.sort { $0.name < $1.name }
        }

        return results
    }

    var hasActiveFilters: Bool {
        selectedCategory != nil ||
        selectedCollection != nil ||
        showInStockOnly ||
        minPrice > 0 ||
        (maxPrice > 0 && maxPrice < maxPriceSliderBound)
    }

    // ── Curated Recommendations (Calm, Editorial Curation) ────
    var recommendedProducts: [Product] {
        guard let client = activeClient else { return [] }
        let all = dataStore.products.filter(\.isActive)
        
        let scored = all.map { product -> (Product, Int) in
            var score = 0
            
            // Preferred categories check
            if let favCats = client.favoriteCategories {
                if favCats.contains(where: { $0.caseInsensitiveCompare(product.category) == .orderedSame || $0.caseInsensitiveCompare(product.subcategory ?? "") == .orderedSame }) {
                    score += 3
                }
            }
            
            // Metals check
            if let favMetals = client.favoriteMetals {
                if let mat = product.material {
                    if favMetals.contains(where: { mat.localizedCaseInsensitiveContains($0) }) {
                        score += 2
                    }
                }
            }
            if let prefMetal = client.preferredMetal {
                if let mat = product.material, mat.localizedCaseInsensitiveContains(prefMetal) {
                    score += 2
                }
            }
            
            // Gemstones check
            if let favGems = client.favoriteGemstones {
                if let desc = product.description {
                    if favGems.contains(where: { desc.localizedCaseInsensitiveContains($0) }) {
                        score += 2
                    }
                }
                if let mat = product.material {
                    if favGems.contains(where: { mat.localizedCaseInsensitiveContains($0) }) {
                        score += 2
                    }
                }
            }
            if let prefGem = client.preferredGemstone {
                if let desc = product.description, desc.localizedCaseInsensitiveContains(prefGem) {
                    score += 2
                }
            }
            
            // Brand matching
            if let prefBrands = client.preferredBrands {
                if prefBrands.localizedCaseInsensitiveContains(product.brand) {
                    score += 1
                }
            }
            
            // Avoid items already wishlisted
            let inWishlist = dataStore.wishlistItems.contains { $0.clientId == client.id && $0.productId == product.id }
            if inWishlist {
                score = 0 // Don't over-recommend wishlisted items
            }
            
            return (product, score)
        }
        
        return scored
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
            .prefix(8)
            .map { $0 }
    }

    // MARK: - Init

    init(dataStore: DataStore, storeId: UUID?, activeClient: ClientProfile? = nil, associateId: UUID? = nil) {
        self.dataStore = dataStore
        self.storeId = storeId
        self.activeClient = activeClient
        self.associateId = associateId
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchProducts()
            if let id = storeId {
                try await dataStore.fetchStockItems(storeId: id)
            }
            if let client = activeClient {
                try await dataStore.fetchWishlistItems(clientId: client.id)
                try await dataStore.fetchCuratedCartsAndItems(forClient: client.id)
            }
            // Seed price bounds from actual data
            let prices = dataStore.products.map(\.price)
            if let maxP = prices.max() {
                let rounded = (maxP / 1000).rounded(.up) * 1000
                maxPriceSliderBound = max(rounded, 10_000)
                maxPrice = maxPriceSliderBound
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Size Match & Helper Logic

    func isSizeMatch(for product: Product) -> Bool {
        guard let client = activeClient else { return true }
        let cat = product.category.lowercased()
        let sub = (product.subcategory ?? "").lowercased()

        if cat.contains("ring") || sub.contains("ring") {
            return client.ringSize != nil
        }
        if cat.contains("watch") || sub.contains("watch") {
            return client.wristSize != nil
        }
        if cat.contains("bracelet") || sub.contains("bracelet") {
            return client.braceletSize != nil || client.wristSize != nil
        }
        if cat.contains("necklace") || sub.contains("necklace") {
            return client.necklaceLength != nil
        }
        if cat.contains("belt") || sub.contains("belt") {
            return client.beltSize != nil
        }
        return true
    }

    func clientSizeLabel(for product: Product) -> String? {
        guard let client = activeClient else { return nil }
        let cat = product.category.lowercased()
        let sub = (product.subcategory ?? "").lowercased()

        if cat.contains("ring") || sub.contains("ring") {
            return client.ringSize.map { "Ring Size: \($0)" }
        }
        if cat.contains("watch") || sub.contains("watch") {
            return client.wristSize.map { "Wrist Size: \($0)" }
        }
        if cat.contains("bracelet") || sub.contains("bracelet") {
            return (client.braceletSize ?? client.wristSize).map { "Bracelet Size: \($0)" }
        }
        if cat.contains("necklace") || sub.contains("necklace") {
            return client.necklaceLength.map { "Necklace: \($0)" }
        }
        if cat.contains("belt") || sub.contains("belt") {
            return client.beltSize.map { "Belt Size: \($0)" }
        }
        return nil
    }

    func hasPreferenceMatch(for product: Product, client: ClientProfile) -> Bool {
        // Categories
        if let favCats = client.favoriteCategories {
            if favCats.contains(where: { $0.caseInsensitiveCompare(product.category) == .orderedSame || $0.caseInsensitiveCompare(product.subcategory ?? "") == .orderedSame }) {
                return true
            }
        }
        // Metal
        if let favMetals = client.favoriteMetals, let mat = product.material {
            if favMetals.contains(where: { mat.localizedCaseInsensitiveContains($0) }) {
                return true
            }
        }
        if let prefMetal = client.preferredMetal, let mat = product.material {
            if mat.localizedCaseInsensitiveContains(prefMetal) {
                return true
            }
        }
        // Gemstone
        if let favGems = client.favoriteGemstones {
            if let desc = product.description, favGems.contains(where: { desc.localizedCaseInsensitiveContains($0) }) {
                return true
            }
            if let mat = product.material, favGems.contains(where: { mat.localizedCaseInsensitiveContains($0) }) {
                return true
            }
        }
        return false
    }

    // MARK: - Wishlist Management

    func isProductInWishlist(_ productId: UUID) -> Bool {
        guard let client = activeClient else { return false }
        return dataStore.wishlistItems.contains { $0.clientId == client.id && $0.productId == productId }
    }

    func toggleWishlist(for product: Product) async {
        guard let client = activeClient else { return }
        if let existing = dataStore.wishlistItems.first(where: { $0.clientId == client.id && $0.productId == product.id }) {
            do {
                try await dataStore.deleteWishlistItem(id: existing.id)
            } catch {
                print("[ProductCatalogViewModel] Error removing from wishlist: \(error)")
            }
        } else {
            let item = WishlistItem(
                id: UUID(),
                clientId: client.id,
                productId: product.id,
                addedAt: Date(),
                isAvailable: product.isActive,
                notifyOnRestock: false,
                notes: nil
            )
            do {
                _ = try await dataStore.createWishlistItem(item)
            } catch {
                print("[ProductCatalogViewModel] Error adding to wishlist: \(error)")
            }
        }
    }

    // MARK: - Curated Cart Integration (Database-backed)

    // MARK: - Stock Helpers

    /// Total available stock for a product at the associate's store.
    func stockQuantity(for productId: UUID) -> Int {
        dataStore.stockItems
            .filter {
                $0.productId == productId &&
                $0.status == .available &&
                (storeId == nil || $0.storeId == storeId)
            }
            .reduce(0) { $0 + $1.quantity }
    }

    /// Returns the cart items from the DataStore for the active client's curated cart.
    /// This is the single source of truth — no separate transient array.
    var cartItems: [CartSelectionItem] {
        guard let client = activeClient else { return [] }
        guard let cart = dataStore.universalCarts.first(where: { $0.clientId == client.id && $0.type == .curated }) else { return [] }
        return dataStore.universalCartItems
            .filter { $0.cartId == cart.id }
            .compactMap { item in
                guard let product = dataStore.product(by: item.productId) else { return nil }
                return CartSelectionItem(id: item.id, product: product, quantity: item.quantity)
            }
    }

    /// Checks whether a product is in the client's curated cart by reading DataStore directly.
    func isInCart(_ productId: UUID) -> Bool {
        guard let client = activeClient else { return false }
        guard let cart = dataStore.universalCarts.first(where: { $0.clientId == client.id && $0.type == .curated }) else { return false }
        return dataStore.universalCartItems.contains { $0.cartId == cart.id && $0.productId == productId }
    }

    /// Toggles a product in/out of the curated cart. Writes directly to the database.
    func toggleCartItem(_ product: Product) {
        guard let client = activeClient, let assocId = associateId else { return }
        Task {
            do {
                if isInCart(product.id) {
                    try await dataStore.removeItemFromCuratedCart(productId: product.id, forClient: client.id)
                } else {
                    try await dataStore.addItemToCuratedCart(
                        productId: product.id,
                        price: product.price,
                        forClient: client.id,
                        associateId: assocId
                    )
                }
            } catch {
                print("[ProductCatalogViewModel] Error toggling cart item: \(error)")
            }
        }
    }
    
    var activeUniversalCart: UniversalCart? {
        guard let client = activeClient else { return nil }
        return dataStore.universalCarts.first(where: { $0.clientId == client.id && $0.type == .curated })
    }

    func updateCartDiscount(_ discount: CartDiscount?) async {
        guard let client = activeClient else { return }
        guard let cart = dataStore.universalCarts.first(where: { $0.clientId == client.id && $0.type == .curated }) else { return }
        
        let updatedCart = cart.applyingDiscount(discount)
        do {
            try await dataStore.updateUniversalCart(updatedCart)
        } catch {
            print("[ProductCatalogViewModel] Error updating cart discount: \(error)")
        }
    }

    func addToCart(_ product: Product) {
        guard let client = activeClient, let assocId = associateId else { return }
        guard !isInCart(product.id) else { return }
        Task {
            do {
                try await dataStore.addItemToCuratedCart(
                    productId: product.id,
                    price: product.price,
                    forClient: client.id,
                    associateId: assocId
                )
            } catch {
                print("[ProductCatalogViewModel] Error adding to cart: \(error)")
            }
        }
    }

    func removeFromCart(_ productId: UUID) {
        guard let client = activeClient else { return }
        Task {
            do {
                try await dataStore.removeItemFromCuratedCart(productId: productId, forClient: client.id)
            } catch {
                print("[ProductCatalogViewModel] Error removing from cart: \(error)")
            }
        }
    }

    func clearCart() {
        guard let client = activeClient else { return }
        let items = cartItems
        Task {
            for item in items {
                do {
                    try await dataStore.removeItemFromCuratedCart(productId: item.productId, forClient: client.id)
                } catch {
                    print("[ProductCatalogViewModel] Error clearing cart item: \(error)")
                }
            }
        }
    }
    
    func saveShowroom() async {
        // Cart is already persisted in the database via addItemToCuratedCart / removeItemFromCuratedCart.
        // This just signals success to the UI.
        isSaving = true
        await MainActor.run {
            showSuccess = true
        }
        await MainActor.run {
            isSaving = false
        }
    }

    // MARK: - Filter Reset

    func clearFilters() {
        selectedCategory = nil
        selectedCollection = nil
        showInStockOnly = false
        minPrice = 0
        maxPrice = maxPriceSliderBound
        searchQuery = ""
    }
}
