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
        
        // 3. Merge into local store arrays safely on MainActor
        await MainActor.run {
            for cart in carts {
                if let idx = self.universalCarts.firstIndex(where: { $0.id == cart.id }) {
                    self.universalCarts[idx] = cart
                } else {
                    self.universalCarts.append(cart)
                }
            }
            
            for item in allItems {
                if let idx = self.universalCartItems.firstIndex(where: { $0.id == item.id }) {
                    self.universalCartItems[idx] = item
                } else {
                    self.universalCartItems.append(item)
                }
            }
        }
    }
}
