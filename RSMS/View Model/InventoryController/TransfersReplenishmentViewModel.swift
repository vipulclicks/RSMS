//
//  TransfersReplenishmentViewModel.swift
//  RSMS
//
//  ViewModel for the Transfers & Replenishment screen.
//  CRUD for inventory movements and movement items.
//

import SwiftUI

@Observable
final class TransfersReplenishmentViewModel {

    private let dataStore: DataStore
    private let storeId: UUID
    private let userId: UUID

    var selectedType: MovementType? = nil
    var isLoading = false
    var errorMessage: String?

    init(dataStore: DataStore, storeId: UUID, userId: UUID) {
        self.dataStore = dataStore
        self.storeId   = storeId
        self.userId    = userId
    }

    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchProducts()
            try await dataStore.fetchStores()
            try await dataStore.fetchInventoryMovements()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Movements
    var allMovements: [InventoryMovement] { dataStore.inventoryMovements }

    var filteredMovements: [InventoryMovement] {
        guard let type = selectedType else { return allMovements }
        return allMovements.filter { $0.type == type }
    }

    var transfers: [InventoryMovement] { allMovements.filter { $0.type == .storeTransfer } }
    var replenishments: [InventoryMovement] { allMovements.filter { $0.type == .dcReplenishment } }
    var vendorReturns: [InventoryMovement] { allMovements.filter { $0.type == .vendorReturn } }

    // MARK: - CRUD
    func createTransferRequest(toStoreId: UUID, reason: String?, notes: String?) async throws {
        let movement = InventoryMovement(
            id: UUID(), type: .storeTransfer,
            sourceId: storeId.uuidString, destinationId: toStoreId.uuidString,
            status: .requested, requestedBy: userId, approvedBy: nil,
            requestedAt: .now, shippedAt: nil, receivedAt: nil,
            asnNumber: nil, itemsExpected: nil, itemsReceived: nil,
            reason: reason, notes: notes
        )
        try await dataStore.createInventoryMovement(movement)
        dataStore.logAudit(storeId: storeId, action: "Transfer Requested", entityType: "InventoryMovement", entityId: movement.id, performedBy: userId)
    }

    func receiveShipment(_ movement: InventoryMovement, itemsReceived: Int) async throws {
        let received = InventoryMovement(
            id: movement.id, type: movement.type,
            sourceId: movement.sourceId, destinationId: movement.destinationId,
            status: .received, requestedBy: movement.requestedBy, approvedBy: movement.approvedBy,
            requestedAt: movement.requestedAt, shippedAt: movement.shippedAt, receivedAt: .now,
            asnNumber: movement.asnNumber, itemsExpected: movement.itemsExpected,
            itemsReceived: itemsReceived, reason: movement.reason, notes: movement.notes
        )
        try await dataStore.updateInventoryMovement(received)
        dataStore.logAudit(storeId: storeId, action: "Shipment Received", entityType: "InventoryMovement", entityId: movement.id, performedBy: userId, details: "\(itemsReceived) items received")
    }

    func createVendorReturn(vendorId: String, reason: String, notes: String?) async throws {
        let movement = InventoryMovement(
            id: UUID(), type: .vendorReturn,
            sourceId: storeId.uuidString, destinationId: vendorId,
            status: .requested, requestedBy: userId, approvedBy: nil,
            requestedAt: .now, shippedAt: nil, receivedAt: nil,
            asnNumber: nil, itemsExpected: nil, itemsReceived: nil,
            reason: reason, notes: notes
        )
        try await dataStore.createInventoryMovement(movement)
    }

    // MARK: - Movement Items
    func items(for movementId: UUID) -> [MovementItem] {
        dataStore.movementItems.filter { $0.movementId == movementId }
    }

    func addMovementItem(movementId: UUID, productId: UUID, qty: Int, reason: String? = nil) async throws {
        let item = MovementItem(id: UUID(), movementId: movementId, productId: productId, quantity: qty, reason: reason)
        try await dataStore.createMovementItem(item)
    }

    func removeMovementItem(id: UUID) async throws {
        try await dataStore.deleteMovementItem(id: id)
    }

    // MARK: - Helpers
    func productName(for id: UUID) -> String { dataStore.productName(for: id) }
    func storeName(for idString: String) -> String {
        if let uuid = UUID(uuidString: idString) { return dataStore.storeName(for: uuid) }
        return idString // DC-IDs or vendor IDs are not UUIDs
    }

    func statusColor(_ status: MovementStatus) -> Color {
        switch status {
        case .requested:  return RSMSTheme.warning
        case .approved:   return RSMSTheme.info
        case .inTransit:  return RSMSTheme.gold
        case .received, .completed: return RSMSTheme.success
        case .cancelled:  return RSMSTheme.danger
        case .partial:    return RSMSTheme.warning
        case .exception:  return RSMSTheme.danger
        }
    }

    func typeIcon(_ type: MovementType) -> String {
        switch type {
        case .storeTransfer:   return "arrow.left.arrow.right"
        case .dcReplenishment: return "shippingbox.fill"
        case .vendorReturn:    return "arrow.uturn.backward.circle.fill"
        }
    }
}
