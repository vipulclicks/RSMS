import Foundation
import SwiftUI

@Observable
final class StockTransfersViewModel {
    var isLoading = false
    var isReceiving = false
    var error: String?
    var selectedTransfer: InventoryMovement?
    
    // Loaded from DataStore
    var allTransfers: [InventoryMovement] = []
    var currentMovementItems: [MovementItem] = []
    
    // Helpers to get store name
    func storeName(for idString: String, dataStore: DataStore) -> String {
        guard let id = UUID(uuidString: idString),
              let store = dataStore.stores.first(where: { $0.id == id }) else {
            return "Unknown Store"
        }
        return store.name
    }
    
    // Computed properties for lists
    func inboundTransfers(for storeId: UUID) -> [InventoryMovement] {
        let storeIdString = storeId.uuidString.lowercased()
        return allTransfers.filter { $0.destinationId.lowercased() == storeIdString && $0.type == .storeTransfer }
            .sorted { ($0.requestedAt ?? .distantPast) > ($1.requestedAt ?? .distantPast) }
    }
    
    func outboundTransfers(for storeId: UUID) -> [InventoryMovement] {
        let storeIdString = storeId.uuidString.lowercased()
        return allTransfers.filter { $0.sourceId.lowercased() == storeIdString && $0.type == .storeTransfer }
            .sorted { ($0.requestedAt ?? .distantPast) > ($1.requestedAt ?? .distantPast) }
    }
    
    @MainActor
    func load(dataStore: DataStore) async {
        isLoading = true
        error = nil
        do {
            try await dataStore.fetchInventoryMovements(type: .storeTransfer)
            allTransfers = dataStore.inventoryMovements
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    func loadDetails(for movement: InventoryMovement, dataStore: DataStore) async {
        isLoading = true
        error = nil
        selectedTransfer = movement
        do {
            try await dataStore.fetchMovementItems(movementId: movement.id)
            currentMovementItems = dataStore.movementItems.filter { $0.movementId == movement.id }
            
            // DEMO FALLBACK: If there are no items for this transfer, inject some locally
            if currentMovementItems.isEmpty, !dataStore.products.isEmpty {
                let firstProduct = dataStore.products[0]
                let secondProduct = dataStore.products.count > 1 ? dataStore.products[1] : firstProduct
                
                let mockItem1 = MovementItem(
                    id: UUID(),
                    movementId: movement.id,
                    productId: firstProduct.id,
                    quantity: 2,
                    reason: nil
                )
                let mockItem2 = MovementItem(
                    id: UUID(),
                    movementId: movement.id,
                    productId: secondProduct.id,
                    quantity: 1,
                    reason: nil
                )
                
                currentMovementItems = firstProduct.id == secondProduct.id ? [mockItem1] : [mockItem1, mockItem2]
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    func receiveTransfer(movement: InventoryMovement, dataStore: DataStore) async {
        isReceiving = true
        error = nil
        
        do {
            // 1. Update transfer status to completed
            let updatedMovement = InventoryMovement(
                id: movement.id,
                type: movement.type,
                sourceId: movement.sourceId,
                destinationId: movement.destinationId,
                status: .completed, // Marked as completed
                requestedBy: movement.requestedBy,
                approvedBy: movement.approvedBy,
                requestedAt: movement.requestedAt,
                shippedAt: movement.shippedAt,
                receivedAt: Date(), // Record receiving time
                asnNumber: movement.asnNumber,
                itemsExpected: movement.itemsExpected,
                itemsReceived: movement.itemsExpected, // Assuming all received
                reason: movement.reason,
                notes: movement.notes
            )
            
            try await dataStore.updateInventoryMovement(updatedMovement)
            
            // 2. Fetch movement items to know what to update
            try await dataStore.fetchMovementItems(movementId: movement.id)
            let items = dataStore.movementItems.filter { $0.movementId == movement.id }
            
            guard let destUUID = UUID(uuidString: movement.destinationId),
                  let sourceUUID = UUID(uuidString: movement.sourceId) else {
                throw NSError(domain: "StockTransfers", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid store IDs in transfer."])
            }
            
            // 3. Update stock levels for both stores
            for item in items {
                // Deduct from Source
                if let sourceStock = dataStore.stockItems.first(where: { $0.productId == item.productId && $0.storeId == sourceUUID }) {
                    let updatedSourceStock = StockItem(
                        id: sourceStock.id,
                        productId: sourceStock.productId,
                        storeId: sourceStock.storeId,
                        quantity: max(0, sourceStock.quantity - item.quantity),
                        rfidTag: sourceStock.rfidTag,
                        location: sourceStock.location,
                        status: sourceStock.status,
                        lastScannedAt: sourceStock.lastScannedAt,
                        updatedAt: Date()
                    )
                    try await dataStore.updateStockItem(updatedSourceStock)
                }
                
                // Add to Destination
                if let destStock = dataStore.stockItems.first(where: { $0.productId == item.productId && $0.storeId == destUUID }) {
                    let updatedDestStock = StockItem(
                        id: destStock.id,
                        productId: destStock.productId,
                        storeId: destStock.storeId,
                        quantity: destStock.quantity + item.quantity,
                        rfidTag: destStock.rfidTag,
                        location: destStock.location,
                        status: destStock.status,
                        lastScannedAt: destStock.lastScannedAt,
                        updatedAt: Date()
                    )
                    try await dataStore.updateStockItem(updatedDestStock)
                }
            }
            
            // Refresh data
            try await dataStore.fetchInventoryMovements(type: .storeTransfer)
            allTransfers = dataStore.inventoryMovements
            
            // Check wishlists and notify sales associates in the destination store
            let destAssociates = dataStore.users.filter { $0.storeId == destUUID && $0.role == .salesAssociate }
            
            for item in items {
                // Find any client wishlists for this product
                let matchingWishlists = dataStore.wishlistItems.filter { $0.productId == item.productId && $0.notifyOnRestock }
                
                if !matchingWishlists.isEmpty {
                    // Fetch product name safely
                    let productName = dataStore.products.first(where: { $0.id == item.productId })?.name ?? "A product"
                    
                    // Notify all sales associates in the destination store
                    for associate in destAssociates {
                        try? await dataStore.createNotification(
                            recipientId: associate.id,
                            title: "Wishlist Item Back in Stock",
                            message: "\(productName) is now back in stock at your store.",
                            type: .wishlistRestock,
                            relatedEntityId: item.productId
                        )
                    }
                }
            }
            
            if selectedTransfer?.id == movement.id {
                selectedTransfer = updatedMovement
            }
            
        } catch {
            self.error = error.localizedDescription
        }
        
        isReceiving = false
    }
}
