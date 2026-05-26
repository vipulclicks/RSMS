//
//  DigitalShowroomViewModel.swift
//  RSMS
//
//  Manages the luxury curated cart ("Digital Showroom") session.
//

import SwiftUI
import Observation

enum ClientReaction: String, CaseIterable, Identifiable {
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

struct ShowroomCartItem: Identifiable, Equatable {
    var id: UUID { product.id }
    let product: Product
    var quantity: Int = 1
    var reaction: ClientReaction?
    var saNote: String = ""
    
    static func == (lhs: ShowroomCartItem, rhs: ShowroomCartItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.quantity == rhs.quantity &&
        lhs.reaction == rhs.reaction &&
        lhs.saNote == rhs.saNote
    }
}

@Observable
@MainActor
final class DigitalShowroomViewModel {
    
    private let dataStore: DataStore
    let client: ClientProfile
    let associateId: UUID
    
    var occasion: String = "Summer Edit"
    var title: String = ""
    var isSaving: Bool = false
    var showSuccess: Bool = false
    
    var cartItems: [ShowroomCartItem] = []
    
    // UI State
    var selectedCategory: String?
    var selectedCollection: String?
    var searchText: String = ""
    var showInStockOnly = false
    var minPrice: Double = 0
    var maxPrice: Double = 0
    var maxPriceSliderBound: Double = 250_000
    
    var trendingProducts: [Product] = []
    var recommendedProducts: [Product] = []
    
    var allProducts: [Product] = []
    var categories: [String] = []
    var availableCollections: [String] = []
    
    init(dataStore: DataStore, client: ClientProfile, associateId: UUID) {
        self.dataStore = dataStore
        self.client = client
        self.associateId = associateId
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        self.title = "Curated Edit - \(formatter.string(from: Date()))"
        
        let all = dataStore.products.filter(\.isActive)
        self.allProducts = all.sorted { $0.name < $1.name }
        self.categories = Array(Set(all.map(\.category))).sorted()
        self.availableCollections = Array(Set(all.compactMap(\.collection))).sorted()
        
        // Seed price bounds
        let prices = all.map(\.price)
        if let maxP = prices.max() {
            let rounded = (maxP / 1000).rounded(.up) * 1000
            self.maxPriceSliderBound = max(rounded, 10_000)
            self.maxPrice = self.maxPriceSliderBound
        }
        
        self.trendingProducts = Array(all.shuffled().prefix(3))
        self.recommendedProducts = Array(all.shuffled().prefix(4))
        
        let existingCarts = dataStore.curatedCarts(for: client.id)
        if let first = existingCarts.first {
            self.title = first.title
            let desc = first.description
            if desc.lowercased().contains("curated cart") {
                self.occasion = ""
            } else {
                self.occasion = desc
            }
            for item in first.items {
                if let product = all.first(where: { $0.id == item.productId }) {
                    let rx = ClientReaction(rawValue: item.note ?? "")
                    self.cartItems.append(ShowroomCartItem(product: product, quantity: item.quantity, reaction: rx, saNote: item.note ?? ""))
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var totalValue: Double {
        cartItems.reduce(0) { $0 + ($1.product.price * Double($1.quantity)) }
    }
    
    var filteredCatalog: [Product] {
        var res = allProducts
        if let cat = selectedCategory {
            res = res.filter { $0.category == cat }
        }
        if let col = selectedCollection {
            res = res.filter { $0.collection == col }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            res = res.filter {
                $0.name.lowercased().contains(q) ||
                $0.sku.lowercased().contains(q) ||
                $0.brand.lowercased().contains(q) ||
                ($0.collection?.lowercased().contains(q) ?? false)
            }
        }
        if maxPrice > 0 && maxPrice < maxPriceSliderBound {
            res = res.filter { $0.price <= maxPrice }
        }
        if minPrice > 0 {
            res = res.filter { $0.price >= minPrice }
        }
        if showInStockOnly {
            res = res.filter { stockQuantity(for: $0.id) > 0 }
        }
        return res
    }
    
    var hasActiveFilters: Bool {
        selectedCategory != nil ||
        selectedCollection != nil ||
        showInStockOnly ||
        minPrice > 0 ||
        (maxPrice > 0 && maxPrice < maxPriceSliderBound)
    }
    
    // MARK: - Stock / Availability Helper
    
    func stockQuantity(for productId: UUID) -> Int {
        dataStore.stockItems
            .filter {
                $0.productId == productId &&
                $0.status == .available
            }
            .reduce(0) { $0 + $1.quantity }
    }
    
    func clearFilters() {
        selectedCategory = nil
        selectedCollection = nil
        showInStockOnly = false
        minPrice = 0
        maxPrice = maxPriceSliderBound
        searchText = ""
    }
    
    // MARK: - Actions
    
    func toggleCartItem(_ product: Product) {
        if let idx = cartItems.firstIndex(where: { $0.product.id == product.id }) {
            cartItems.remove(at: idx)
        } else {
            cartItems.append(ShowroomCartItem(product: product))
        }
    }
    
    func isInCart(_ product: Product) -> Bool {
        cartItems.contains { $0.product.id == product.id }
    }
    
    func addToWishlist(_ product: Product) async {
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
    
    func setReaction(for productId: UUID, reaction: ClientReaction?) {
        if let idx = cartItems.firstIndex(where: { $0.product.id == productId }) {
            cartItems[idx].reaction = reaction
        }
    }
    
    func setNote(for productId: UUID, note: String) {
        if let idx = cartItems.firstIndex(where: { $0.product.id == productId }) {
            cartItems[idx].saNote = note
        }
    }
    
    func saveShowroom() async {
        guard !cartItems.isEmpty else { return }
        isSaving = true
        
        let uItems: [UniversalCartItem] = cartItems.map { item in
            let noteStr = item.saNote.isEmpty ? nil : item.saNote
            return UniversalCartItem(
                id: UUID(),
                cartId: UUID(), // temporary
                productId: item.product.id,
                quantity: item.quantity,
                unitPrice: item.product.price,
                discountApplied: 0,
                note: noteStr
            )
        }
        
        let cart = CuratedCart(
            id: UUID(),
            title: title,
            description: occasion,
            items: uItems
        )
        
        do {
            try await dataStore.saveCuratedCart(cart, forClient: client.id, associateId: associateId)
            showSuccess = true
        } catch {
            print("[DigitalShowroomViewModel] Save error: \(error)")
        }
        
        isSaving = false
    }
    
    func reloadFromDataStore() {
        let all = dataStore.products.filter(\.isActive)
        let existingCarts = dataStore.curatedCarts(for: client.id)
        
        self.cartItems.removeAll()
        
        if let first = existingCarts.first {
            self.title = first.title
            let desc = first.description
            if desc.lowercased().contains("curated cart") {
                self.occasion = ""
            } else {
                self.occasion = desc
            }
            for item in first.items {
                if let product = all.first(where: { $0.id == item.productId }) {
                    let rx = ClientReaction(rawValue: item.note ?? "")
                    self.cartItems.append(ShowroomCartItem(product: product, quantity: item.quantity, reaction: rx, saNote: item.note ?? ""))
                }
            }
        }
    }
}

extension DigitalShowroomViewModel: Identifiable, Hashable {
    public var id: UUID { client.id }
    
    public static func == (lhs: DigitalShowroomViewModel, rhs: DigitalShowroomViewModel) -> Bool {
        lhs === rhs
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
