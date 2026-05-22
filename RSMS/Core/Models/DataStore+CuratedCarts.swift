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
}
