//
//  InventorySourcingViewModel.swift
//  RSMS
//

import SwiftUI
import Observation

@Observable
final class InventorySourcingViewModel {
    
    var requests: [InventorySourcingRequest] = []
    var isLoading = false
    var errorMessage: String?
    var isSubmitting = false
    var showSuccess = false
    
    init() {}
    
    // MARK: - Filtering
    
    func pendingRequests(for associateId: UUID? = nil) -> [InventorySourcingRequest] {
        requests.filter { req in
            let matchAssociate = associateId == nil || req.salesAssociateId == associateId
            return matchAssociate && (req.status == .requested || req.status == .searching || req.status == .stockFound)
        }.sorted { $0.createdAt > $1.createdAt }
    }
    
    func activeRequests(for associateId: UUID? = nil) -> [InventorySourcingRequest] {
        requests.filter { req in
            let matchAssociate = associateId == nil || req.salesAssociateId == associateId
            return matchAssociate && (req.status == .transferInitiated || req.status == .inTransit || req.status == .received)
        }.sorted { $0.createdAt > $1.createdAt }
    }
    
    func completedRequests(for associateId: UUID? = nil) -> [InventorySourcingRequest] {
        requests.filter { req in
            let matchAssociate = associateId == nil || req.salesAssociateId == associateId
            return matchAssociate && (req.status == .available || req.status == .completed || req.status == .cancelled)
        }.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Load
    
    @MainActor
    func load(dataStore: DataStore) async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchInventorySourcingRequests()
            try await dataStore.fetchStores()
            try await dataStore.fetchProducts()
            try await dataStore.fetchStockItems()
            try await dataStore.fetchInventoryMovements()
            try await dataStore.fetchUsers()
            
            self.requests = dataStore.inventorySourcingRequests
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Sales Associate actions
    
    @MainActor
    func submitRequest(
        dataStore: DataStore,
        productId: UUID,
        productName: String,
        quantity: Int,
        associateId: UUID,
        storeId: UUID
    ) async {
        isSubmitting = true
        errorMessage = nil
        
        let request = InventorySourcingRequest(
            id: UUID(),
            productId: productId,
            productName: productName,
            requestedQuantity: quantity,
            requestingStoreId: storeId,
            salesAssociateId: associateId,
            createdAt: Date(),
            status: .requested
        )
        
        do {
            try await dataStore.createInventorySourcingRequest(request)
            self.requests = dataStore.inventorySourcingRequests
            
            // Notify inventory controllers in the store
            let controllers = dataStore.users.filter { $0.role == .inventoryController }
            for controller in controllers {
                try? await dataStore.createNotification(
                    recipientId: controller.id,
                    title: "New Inventory Sourcing Requested",
                    message: "Item '\(productName)' (Qty: \(quantity)) is requested for store transfer.",
                    type: .sourcingRequest,
                    relatedEntityId: request.id
                )
            }
            
            withAnimation {
                showSuccess = true
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
    
    // MARK: - Status Transitions
    
    @MainActor
    func updateRequestStatus(
        dataStore: DataStore,
        request: InventorySourcingRequest,
        status: InventorySourcingStatus
    ) async {
        var updated = request
        updated.status = status
        
        do {
            try await dataStore.updateInventorySourcingRequest(updated)
            self.requests = dataStore.inventorySourcingRequests
            
            // If marked available, notify sales associate
            if status == .available {
                try? await dataStore.createNotification(
                    recipientId: request.salesAssociateId,
                    title: "Sourcing Request Available",
                    message: "Requested item '\(request.productName)' is now available in inventory.",
                    type: .sourcingRequest,
                    relatedEntityId: request.id
                )
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Inventory Controller Sourcing Workflow
    
    @MainActor
    func initiateTransfer(
        dataStore: DataStore,
        request: InventorySourcingRequest,
        sourceStoreId: UUID,
        controllerId: UUID
    ) async {
        isLoading = true
        errorMessage = nil
        
        // 1. Create InventoryMovement (using existing transfer model)
        let movement = InventoryMovement(
            id: UUID(),
            type: .storeTransfer,
            sourceId: sourceStoreId.uuidString,
            destinationId: request.requestingStoreId.uuidString,
            status: .requested,
            requestedBy: request.salesAssociateId,
            approvedBy: controllerId,
            requestedAt: Date(),
            shippedAt: nil,
            receivedAt: nil,
            asnNumber: nil,
            itemsExpected: request.requestedQuantity,
            itemsReceived: nil,
            reason: "Sourcing Request — \(request.productName)",
            notes: "[SOURCING] Linked Sourcing Request ID: \(request.id)"
        )
        
        do {
            // Save movement
            let createdMovement = try await dataStore.createInventoryMovement(movement)
            
            // 2. Create MovementItem
            let item = MovementItem(
                id: UUID(),
                movementId: createdMovement.id,
                productId: request.productId,
                quantity: request.requestedQuantity,
                reason: "Sourcing Request"
            )
            try await dataStore.createMovementItem(item)
            
            // 3. Update Request status to Transfer Initiated
            var updatedRequest = request
            updatedRequest.sourceStoreId = sourceStoreId
            updatedRequest.transferMovementId = createdMovement.id
            updatedRequest.status = .transferInitiated
            
            try await dataStore.updateInventorySourcingRequest(updatedRequest)
            
            // 4. Notify Sales Associate
            try await dataStore.createNotification(
                recipientId: request.salesAssociateId,
                title: "Stock Found & Transfer Initiated",
                message: "Stock for \(request.productName) has been found and a transfer is initiated.",
                type: .sourcingRequest,
                relatedEntityId: request.id
            )
            
            // Refresh requests list
            self.requests = dataStore.inventorySourcingRequests
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    func markTransferCompletedAndAvailable(
        dataStore: DataStore,
        request: InventorySourcingRequest
    ) async {
        guard let movementId = request.transferMovementId else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Retrieve the linked movement
            try await dataStore.fetchInventoryMovements(type: .storeTransfer)
            guard let movement = dataStore.inventoryMovements.first(where: { $0.id == movementId }) else {
                throw NSError(domain: "Sourcing", code: 404, userInfo: [NSLocalizedDescriptionKey: "Linked transfer movement not found."])
            }
            
            // 2. Mark movement as completed
            let updatedMovement = InventoryMovement(
                id: movement.id,
                type: movement.type,
                sourceId: movement.sourceId,
                destinationId: movement.destinationId,
                status: .completed,
                requestedBy: movement.requestedBy,
                approvedBy: movement.approvedBy,
                requestedAt: movement.requestedAt,
                shippedAt: movement.shippedAt ?? Date(),
                receivedAt: Date(),
                asnNumber: movement.asnNumber,
                itemsExpected: movement.itemsExpected,
                itemsReceived: movement.itemsExpected,
                reason: movement.reason,
                notes: movement.notes
            )
            try await dataStore.updateInventoryMovement(updatedMovement)
            
            // 3. Update stock levels: Deduct from source, add to destination
            guard let srcUUID = UUID(uuidString: movement.sourceId),
                  let destUUID = UUID(uuidString: movement.destinationId) else {
                throw NSError(domain: "Sourcing", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid store IDs in linked transfer."])
            }
            
            // Fetch stock items for BOTH stores so the local cache is complete
            try await dataStore.fetchStockItems()
            
            // Deduct from Source
            if let sourceStock = dataStore.stockItems.first(where: { $0.productId == request.productId && $0.storeId == srcUUID }) {
                let updatedSourceStock = StockItem(
                    id: sourceStock.id,
                    productId: sourceStock.productId,
                    storeId: sourceStock.storeId,
                    quantity: max(0, sourceStock.quantity - request.requestedQuantity),
                    rfidTag: sourceStock.rfidTag,
                    location: sourceStock.location,
                    status: sourceStock.status,
                    lastScannedAt: sourceStock.lastScannedAt,
                    updatedAt: Date()
                )
                try await dataStore.updateStockItem(updatedSourceStock)
            }
            
            // Add to Destination — always set status to .available
            if let destStock = dataStore.stockItems.first(where: { $0.productId == request.productId && $0.storeId == destUUID }) {
                let updatedDestStock = StockItem(
                    id: destStock.id,
                    productId: destStock.productId,
                    storeId: destStock.storeId,
                    quantity: destStock.quantity + request.requestedQuantity,
                    rfidTag: destStock.rfidTag,
                    location: destStock.location,
                    status: .available,
                    lastScannedAt: Date(),
                    updatedAt: Date()
                )
                try await dataStore.updateStockItem(updatedDestStock)
            } else {
                // If destination stock item doesn't exist, create it
                let newDestStock = StockItem(
                    id: UUID(),
                    productId: request.productId,
                    storeId: destUUID,
                    quantity: request.requestedQuantity,
                    rfidTag: nil,
                    location: "Showroom Floor",
                    status: .available,
                    lastScannedAt: Date(),
                    updatedAt: Date()
                )
                try await dataStore.createStockItem(newDestStock)
            }
            
            // 4. Transition Request status to Available
            var updatedRequest = request
            updatedRequest.status = .available
            try await dataStore.updateInventorySourcingRequest(updatedRequest)
            
            // 5. Send notification to Sales Associate
            try await dataStore.createNotification(
                recipientId: request.salesAssociateId,
                title: "Requested Item Available",
                message: "Requested item '\(request.productName)' is now available in inventory.",
                type: .sourcingRequest,
                relatedEntityId: request.id
            )
            
            // Refresh data stores
            try await dataStore.fetchInventorySourcingRequests()
            try await dataStore.fetchStockItems()
            self.requests = dataStore.inventorySourcingRequests
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
