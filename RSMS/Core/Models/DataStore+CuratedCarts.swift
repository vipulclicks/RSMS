// DataStore+CuratedCarts.swift
import Foundation

extension DataStore {
    /// Returns curated carts for a given client based on the universal_carts table.
    func curatedCarts(for clientID: UUID) -> [CuratedCart] {
        // Map universal carts that belong to the client and are of type 'curated'
        let carts = universalCarts.filter { $0.clientId == clientID && $0.type == .curated }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return carts.map { cart in
            let items = universalCartItems.filter { $0.cartId == cart.id }
            let title = "Curated Cart - \(formatter.string(from: cart.createdAt))"
            let description = cart.note ?? "No notes provided"
            return CuratedCart(id: cart.id,
                               title: title,
                               description: description,
                               items: items)
        }
    }

    // MARK: - Get or Create the single curated cart for a client
    
    /// Returns the existing curated cart for a client, or creates a new empty one.
    /// This ensures there is always exactly one curated cart per client.
    func getOrCreateCuratedCart(forClient clientId: UUID, associateId: UUID) async throws -> UniversalCart {
        // Check local state first
        if let existing = universalCarts.first(where: { $0.clientId == clientId && $0.type == .curated }) {
            return existing
        }
        
        // Check database
        let fetched: [UniversalCart] = try await SupabaseClient.shared.fetch("universal_carts", query: [
            "client_id": "eq.\(clientId)",
            "type": "eq.curated"
        ])
        
        if let existing = fetched.first {
            await MainActor.run {
                if !self.universalCarts.contains(where: { $0.id == existing.id }) {
                    self.universalCarts.append(existing)
                }
            }
            return existing
        }
        
        // Create a new cart
        let newCart = UniversalCart(
            id: UUID(),
            type: .curated,
            associateId: associateId,
            clientId: clientId,
            storeId: nil,
            status: .active,
            note: "Curated Cart",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let created: UniversalCart = try await SupabaseClient.shared.insert("universal_carts", record: newCart)
        await MainActor.run {
            self.universalCarts.append(created)
        }
        return created
    }
    
    // MARK: - Add a single item (non-destructive append)
    
    /// Adds a single product to the client's curated cart.
    /// If the product is already in the cart, this is a no-op.
    /// This does NOT remove any existing items.
    func addItemToCuratedCart(productId: UUID, price: Double, forClient clientId: UUID, associateId: UUID, note: String? = nil) async throws {
        let cart = try await getOrCreateCuratedCart(forClient: clientId, associateId: associateId)
        
        // Check if item already exists in this cart
        let alreadyExists = universalCartItems.contains { $0.cartId == cart.id && $0.productId == productId }
        guard !alreadyExists else { return }
        
        let newItem = UniversalCartItem(
            id: UUID(),
            cartId: cart.id,
            productId: productId,
            quantity: 1,
            unitPrice: price,
            discountApplied: 0,
            note: note
        )
        
        let inserted: UniversalCartItem = try await SupabaseClient.shared.insert("universal_cart_items", record: newItem)
        await MainActor.run {
            self.universalCartItems.append(inserted)
        }
    }
    
    // MARK: - Remove a single item
    
    /// Removes a single product from the client's curated cart.
    func removeItemFromCuratedCart(productId: UUID, forClient clientId: UUID) async throws {
        guard let cart = universalCarts.first(where: { $0.clientId == clientId && $0.type == .curated }) else { return }
        guard let item = universalCartItems.first(where: { $0.cartId == cart.id && $0.productId == productId }) else { return }
        
        try await SupabaseClient.shared.delete("universal_cart_items", id: item.id)
        await MainActor.run {
            self.universalCartItems.removeAll { $0.id == item.id }
        }
    }
    
    // MARK: - Full cart replace (used by Guided Catalog save)

    func saveCuratedCart(_ cart: CuratedCart, forClient clientId: UUID, associateId: UUID) async throws {
        // Enforce one curated cart per client: delete any existing ones first
        let existing = self.universalCarts.filter { $0.clientId == clientId && $0.type == .curated }
        if !existing.isEmpty {
            try await withThrowingTaskGroup(of: UUID.self) { group in
                for oldCart in existing {
                    group.addTask {
                        try await SupabaseClient.shared.delete("universal_carts", id: oldCart.id)
                        return oldCart.id
                    }
                }
                while let deletedId = try await group.next() {
                    await MainActor.run {
                        self.universalCarts.removeAll { $0.id == deletedId }
                        self.universalCartItems.removeAll { $0.cartId == deletedId }
                    }
                }
            }
        }
        
        let uniCart = UniversalCart(
            id: cart.id,
            type: .curated,
            associateId: associateId,
            clientId: clientId,
            storeId: nil,
            status: .active,
            note: cart.description,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let createdCart: UniversalCart = try await SupabaseClient.shared.insert("universal_carts", record: uniCart)
        
        let itemsToInsert = cart.items.map { item in
            UniversalCartItem(
                id: item.id,
                cartId: createdCart.id,
                productId: item.productId,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                discountApplied: item.discountApplied,
                note: item.note
            )
        }
        
        if !itemsToInsert.isEmpty {
            let insertedItems = try await SupabaseClient.shared.insertMany("universal_cart_items", records: itemsToInsert)
            await MainActor.run {
                self.universalCartItems.append(contentsOf: insertedItems)
            }
        }
        
        await MainActor.run {
            self.universalCarts.append(createdCart)
        }
    }

    /// Fetches all curated carts and their associated items from the database for a given client.
    func fetchCuratedCartsAndItems(forClient clientId: UUID) async throws {
        // 1. Fetch curated carts for the client
        let carts: [UniversalCart] = try await SupabaseClient.shared.fetch("universal_carts", query: [
            "client_id": "eq.\(clientId)",
            "type": "eq.curated"
        ])
        
        // 2. Fetch items for all these carts concurrently
        var allItems: [UniversalCartItem] = []
        if !carts.isEmpty {
            try await withThrowingTaskGroup(of: [UniversalCartItem].self) { group in
                for cart in carts {
                    group.addTask {
                        try await SupabaseClient.shared.fetch("universal_cart_items", query: ["cart_id": "eq.\(cart.id)"])
                    }
                }
                while let items = try await group.next() {
                    allItems.append(contentsOf: items)
                }
            }
        }
        
        // 3. Replace local state for this client's curated carts cleanly
        await MainActor.run {
            // Remove old local data for this client's curated carts
            let oldCartIds = Set(self.universalCarts.filter { $0.clientId == clientId && $0.type == .curated }.map { $0.id })
            self.universalCarts.removeAll { $0.clientId == clientId && $0.type == .curated }
            self.universalCartItems.removeAll { oldCartIds.contains($0.cartId) }
            
            // Add fresh data
            self.universalCarts.append(contentsOf: carts)
            self.universalCartItems.append(contentsOf: allItems)
        }
    }
}
