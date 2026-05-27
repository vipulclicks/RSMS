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
    
    // MARK: - Smart Recommendation Engine
    
    /// Products to exclude from all recommendations (already wishlisted or in cart)
    private var excludedProductIds: Set<UUID> {
        let wishlistIds = Set(allWishlistProducts.map { $0.id })
        let cartIds: Set<UUID> = {
            guard let cart = dataStore.universalCarts.first(where: { $0.clientId == client.id && $0.type == .curated }) else { return [] }
            return Set(dataStore.universalCartItems.filter { $0.cartId == cart.id }.map { $0.productId })
        }()
        return wishlistIds.union(cartIds)
    }
    
    /// All active products not in wishlist or cart
    private var candidateProducts: [Product] {
        let excluded = excludedProductIds
        return dataStore.products.filter { $0.isActive && !excluded.contains($0.id) }
    }
    
    /// Whether the wishlist has enough items to generate contextual (cross-sell) recommendations
    var hasWishlistItems: Bool {
        !allWishlistProducts.isEmpty
    }
    
    // MARK: - Empty Wishlist: Preference-Based Recommendations
    
    /// "Recommended For Client" — scored by client preference profile
    var recommendedForClient: [Product] {
        let candidates = candidateProducts
        
        let scored = candidates.map { product -> (Product, Int) in
            var score = 0
            
            // Favorite categories (+3)
            if let favCats = client.favoriteCategories {
                if favCats.contains(where: {
                    $0.caseInsensitiveCompare(product.category) == .orderedSame ||
                    $0.caseInsensitiveCompare(product.subcategory ?? "") == .orderedSame
                }) {
                    score += 3
                }
            }
            
            // Preferred metals (+2)
            if let favMetals = client.favoriteMetals, let mat = product.material {
                if favMetals.contains(where: { mat.localizedCaseInsensitiveContains($0) }) {
                    score += 2
                }
            }
            if let prefMetal = client.preferredMetal, let mat = product.material {
                if mat.localizedCaseInsensitiveContains(prefMetal) {
                    score += 2
                }
            }
            
            // Gemstones (+2)
            if let favGems = client.favoriteGemstones {
                if let desc = product.description, favGems.contains(where: { desc.localizedCaseInsensitiveContains($0) }) {
                    score += 2
                }
                if let mat = product.material, favGems.contains(where: { mat.localizedCaseInsensitiveContains($0) }) {
                    score += 2
                }
            }
            if let prefGem = client.preferredGemstone {
                if let desc = product.description, desc.localizedCaseInsensitiveContains(prefGem) {
                    score += 2
                }
            }
            
            // Brand matching (+2)
            if let prefBrands = client.preferredBrands {
                if prefBrands.localizedCaseInsensitiveContains(product.brand) {
                    score += 2
                }
            }
            
            // Style preference (+1)
            if let style = client.stylePreference, let desc = product.description {
                if desc.localizedCaseInsensitiveContains(style) { score += 1 }
            }
            
            // Favorite colors (+1)
            if let colors = client.favoriteColors, let mat = product.material {
                for color in colors.components(separatedBy: ",").map({ $0.trimmingCharacters(in: .whitespaces) }) {
                    if mat.localizedCaseInsensitiveContains(color) || product.name.localizedCaseInsensitiveContains(color) {
                        score += 1
                        break
                    }
                }
            }
            
            // VIP tier boost — higher-priced items for Platinum/Privé
            if (client.vipTier == .platinum || client.vipTier == .prive) && product.price > 5000 {
                score += 1
            }
            
            return (product, score)
        }
        
        return scored
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .prefix(6)
            .map { $0.0 }
    }
    
    // MARK: - Wishlist-Based: Contextual Recommendations
    
    /// Cross-category pairing map for luxury clienteling
    private static let complementaryCategories: [String: [String]] = [
        "watches": ["accessories", "jewelry", "leather goods"],
        "jewelry": ["watches", "accessories", "fragrances"],
        "handbags": ["accessories", "scarves", "jewelry", "leather goods"],
        "shoes": ["belts", "leather goods", "accessories"],
        "belts": ["shoes", "leather goods", "accessories"],
        "fragrances": ["jewelry", "accessories"],
        "accessories": ["jewelry", "watches", "handbags"],
        "leather goods": ["accessories", "belts", "shoes"],
        "scarves": ["handbags", "jewelry", "accessories"],
        "eyewear": ["accessories", "jewelry"],
    ]
    
    /// "Complete The Look" — cross-category complements based on wishlist items
    var completeTheLook: [Product] {
        let wishlistCats = Set(allWishlistProducts.map { $0.category.lowercased() })
        
        // Gather all complementary categories
        var targetCats = Set<String>()
        for cat in wishlistCats {
            if let complements = Self.complementaryCategories[cat] {
                targetCats.formUnion(complements)
            }
        }
        // Remove categories already in wishlist
        targetCats.subtract(wishlistCats)
        
        guard !targetCats.isEmpty else { return [] }
        
        let candidates = candidateProducts.filter { product in
            targetCats.contains(product.category.lowercased())
        }
        
        // Score by preference affinity
        let scored = candidates.map { product -> (Product, Int) in
            var score = 1
            if let favCats = client.favoriteCategories {
                if favCats.contains(where: { $0.caseInsensitiveCompare(product.category) == .orderedSame }) { score += 2 }
            }
            if let prefBrands = client.preferredBrands, prefBrands.localizedCaseInsensitiveContains(product.brand) { score += 1 }
            // Prefer products from the same brands already in wishlist
            let wishlistBrands = Set(allWishlistProducts.map { $0.brand.lowercased() })
            if wishlistBrands.contains(product.brand.lowercased()) { score += 2 }
            return (product, score)
        }
        
        return scored
            .sorted { $0.1 > $1.1 }
            .prefix(6)
            .map { $0.0 }
    }
    
    /// "Premium Alternatives" — same category, higher price tier
    var premiumAlternatives: [Product] {
        let wishlistCats = Set(allWishlistProducts.map { $0.category.lowercased() })
        guard !wishlistCats.isEmpty else { return [] }
        
        let candidates = candidateProducts.filter { product in
            wishlistCats.contains(product.category.lowercased())
        }
        
        // Sort by price descending to surface the most premium options available in those categories
        return candidates
            .sorted { $0.price > $1.price }
            .prefix(6)
            .map { $0 }
    }
    
    /// Whether we have any recommendations to show at all
    var hasRecommendations: Bool {
        if hasWishlistItems {
            return !completeTheLook.isEmpty || !premiumAlternatives.isEmpty
        } else {
            return !recommendedForClient.isEmpty
        }
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
