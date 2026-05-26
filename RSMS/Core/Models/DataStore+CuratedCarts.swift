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

    /// Saves a curated cart to Supabase.
    /// Maps the local `CuratedCart` model into the `curated_carts` table.
    func saveCuratedCart(_ cart: CuratedCart, forClient clientId: UUID) async throws {
        struct CuratedCartInsert: Codable {
            let id: UUID
            let clientId: UUID
            let title: String
            let description: String
            let createdAt: Date

            enum CodingKeys: String, CodingKey {
                case id, title, description
                case clientId   = "client_id"
                case createdAt  = "created_at"
            }
        }

        let insert = CuratedCartInsert(
            id: cart.id,
            clientId: clientId,
            title: cart.title,
            description: cart.description,
            createdAt: Date()
        )
        let _: CuratedCartInsert = try await SupabaseClient.shared.insert("curated_carts", record: insert)

        struct CuratedCartItemInsert: Codable {
            let id: UUID
            let cartId: UUID
            let productId: UUID
            let quantity: Int
            let unitPrice: Double

            enum CodingKeys: String, CodingKey {
                case id, quantity
                case cartId     = "cart_id"
                case productId  = "product_id"
                case unitPrice  = "unit_price"
            }
        }

        for item in cart.items {
            let itemInsert = CuratedCartItemInsert(
                id: item.id,
                cartId: cart.id,
                productId: item.productId,
                quantity: item.quantity,
                unitPrice: item.unitPrice ?? 0.0
            )
            let _: CuratedCartItemInsert = try await SupabaseClient.shared.insert("curated_cart_items", record: itemInsert)
        }
    }
}
