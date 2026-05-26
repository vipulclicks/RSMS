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

// MARK: - Cart Selection Item

struct CartSelectionItem: Identifiable, Hashable {
    let id: UUID
    let productId: UUID
}

// MARK: - ProductCatalogViewModel

@Observable
final class ProductCatalogViewModel {

    // ── Dependencies ──────────────────────────────────────────
    private let dataStore: DataStore
    private let storeId: UUID?

    // ── State ─────────────────────────────────────────────────
    var isLoading = false
    var errorMessage: String?

    // ── Filter State ──────────────────────────────────────────
    var searchQuery = ""
    var selectedCategory: String?
    var selectedCollection: String?
    var showInStockOnly = false

    // Price range (driven by slider; initialised to 0...maxPriceSliderBound)
    var minPrice: Double = 0
    var maxPrice: Double = 0
    private(set) var maxPriceSliderBound: Double = 100_000

    // ── Cart Selection ────────────────────────────────────────
    private(set) var cartItems: [CartSelectionItem] = []

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

        return results.sorted { $0.name < $1.name }
    }

    var hasActiveFilters: Bool {
        selectedCategory != nil ||
        selectedCollection != nil ||
        showInStockOnly ||
        minPrice > 0 ||
        (maxPrice > 0 && maxPrice < maxPriceSliderBound)
    }

    // MARK: - Init

    init(dataStore: DataStore, storeId: UUID?) {
        self.dataStore = dataStore
        self.storeId = storeId
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

    // MARK: - Cart Management

    func isInCart(_ productId: UUID) -> Bool {
        cartItems.contains { $0.productId == productId }
    }

    func addToCart(_ product: Product) {
        guard !isInCart(product.id) else { return }
        cartItems.append(CartSelectionItem(id: UUID(), productId: product.id))
    }

    func removeFromCart(_ productId: UUID) {
        cartItems.removeAll { $0.productId == productId }
    }

    func clearCart() {
        cartItems.removeAll()
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
