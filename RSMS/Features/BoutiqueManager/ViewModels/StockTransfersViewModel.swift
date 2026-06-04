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
            // If no items found, the list will be empty — the View shows an empty state.
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    func approveTransfer(movement: InventoryMovement, dataStore: DataStore, user: UserProfile) async {
        isReceiving = true
        error = nil
        do {
            let updatedMovement = InventoryMovement(
                id: movement.id,
                type: movement.type,
                sourceId: movement.sourceId,
                destinationId: movement.destinationId,
                status: .inTransit, // Approved and shipped
                requestedBy: movement.requestedBy,
                approvedBy: user.id,
                requestedAt: movement.requestedAt,
                shippedAt: Date(),
                receivedAt: nil,
                asnNumber: movement.asnNumber,
                itemsExpected: movement.itemsExpected,
                itemsReceived: nil,
                reason: movement.reason,
                notes: movement.notes
            )
            try await dataStore.updateInventoryMovement(updatedMovement)
            
            try await dataStore.fetchInventoryMovements(type: .storeTransfer)
            allTransfers = dataStore.inventoryMovements
            
            dataStore.logAudit(
                storeId: user.storeId ?? UUID(),
                action: "Transfer Approved",
                entityType: "InventoryMovement",
                entityId: movement.id,
                performedBy: user.id,
                details: "Approved transfer of \(movement.itemsExpected) items to destination."
            )
        } catch {
            self.error = error.localizedDescription
        }
        isReceiving = false
    }

    @MainActor
    func rejectTransfer(movement: InventoryMovement, dataStore: DataStore, user: UserProfile) async {
        isReceiving = true
        error = nil
        do {
            let updatedMovement = InventoryMovement(
                id: movement.id,
                type: movement.type,
                sourceId: movement.sourceId,
                destinationId: movement.destinationId,
                status: .cancelled, // Rejected
                requestedBy: movement.requestedBy,
                approvedBy: user.id,
                requestedAt: movement.requestedAt,
                shippedAt: nil,
                receivedAt: nil,
                asnNumber: movement.asnNumber,
                itemsExpected: movement.itemsExpected,
                itemsReceived: 0,
                reason: movement.reason,
                notes: (movement.notes ?? "") + " [REJECTED BY BM]"
            )
            try await dataStore.updateInventoryMovement(updatedMovement)
            
            // Restore reserved stock
            if let sourceUUID = UUID(uuidString: movement.sourceId) {
                try await dataStore.fetchMovementItems(movementId: movement.id)
                let items = dataStore.movementItems.filter { $0.movementId == movement.id }
                
                for item in items {
                    // Decrement the in-transit item
                    if let inTransit = dataStore.stockItems.first(where: { $0.productId == item.productId && $0.storeId == sourceUUID && $0.status == .inTransit }) {
                        let updatedInTransit = StockItem(
                            id: inTransit.id,
                            productId: inTransit.productId,
                            storeId: inTransit.storeId,
                            quantity: max(0, inTransit.quantity - item.quantity),
                            rfidTag: inTransit.rfidTag,
                            location: inTransit.location,
                            status: .inTransit,
                            lastScannedAt: inTransit.lastScannedAt,
                            updatedAt: Date()
                        )
                        try await dataStore.updateStockItem(updatedInTransit)
                        
                        // Clean up zero quantity transit records to keep DB clean
                        if updatedInTransit.quantity == 0 {
                            try await dataStore.deleteStockItem(id: inTransit.id)
                        }
                    }
                    // Restore quantity to available stock
                    if let availableStock = dataStore.stockItems.first(where: { $0.productId == item.productId && $0.storeId == sourceUUID && $0.status == .available }) {
                        let updated = StockItem(
                            id: availableStock.id,
                            productId: availableStock.productId,
                            storeId: availableStock.storeId,
                            quantity: availableStock.quantity + item.quantity,
                            rfidTag: availableStock.rfidTag,
                            location: availableStock.location,
                            status: .available,
                            lastScannedAt: availableStock.lastScannedAt,
                            updatedAt: Date()
                        )
                        try await dataStore.updateStockItem(updated)
                    }
                }
            }
            
            try await dataStore.fetchInventoryMovements(type: .storeTransfer)
            allTransfers = dataStore.inventoryMovements
            
            dataStore.logAudit(
                storeId: user.storeId ?? UUID(),
                action: "Transfer Rejected",
                entityType: "InventoryMovement",
                entityId: movement.id,
                performedBy: user.id,
                details: "Rejected transfer request and restored reserved stock."
            )
        } catch {
            self.error = error.localizedDescription
        }
        isReceiving = false
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
                // Deduct from Source's inTransit stock
                if let inTransitStock = dataStore.stockItems.first(where: { $0.productId == item.productId && $0.storeId == sourceUUID && $0.status == .inTransit }) {
                    let updatedSourceStock = StockItem(
                        id: inTransitStock.id,
                        productId: inTransitStock.productId,
                        storeId: inTransitStock.storeId,
                        quantity: max(0, inTransitStock.quantity - item.quantity),
                        rfidTag: inTransitStock.rfidTag,
                        location: inTransitStock.location,
                        status: .inTransit,
                        lastScannedAt: inTransitStock.lastScannedAt,
                        updatedAt: Date()
                    )
                    try await dataStore.updateStockItem(updatedSourceStock)
                    
                    // Clean up zero quantity transit records
                    if updatedSourceStock.quantity == 0 {
                        try await dataStore.deleteStockItem(id: inTransitStock.id)
                    }
                }
                
                // Add to Destination's available stock
                if let destStock = dataStore.stockItems.first(where: { $0.productId == item.productId && $0.storeId == destUUID && $0.status == .available }) {
                    let updatedDestStock = StockItem(
                        id: destStock.id,
                        productId: destStock.productId,
                        storeId: destStock.storeId,
                        quantity: destStock.quantity + item.quantity,
                        rfidTag: destStock.rfidTag,
                        location: destStock.location,
                        status: .available,
                        lastScannedAt: destStock.lastScannedAt,
                        updatedAt: Date()
                    )
                    try await dataStore.updateStockItem(updatedDestStock)
                } else {
                    // Create new stock entry at destination if none exists
                    let newDestStock = StockItem(
                        id: UUID(),
                        productId: item.productId,
                        storeId: destUUID,
                        quantity: item.quantity,
                        rfidTag: nil,
                        location: "Backroom", // Default location
                        status: .available,
                        lastScannedAt: Date(),
                        updatedAt: Date()
                    )
                    try await dataStore.createStockItem(newDestStock)
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
