//
//  InventoryOpsViewModel.swift
//  RSMS
//
//  ViewModel for the manager-facing Inventory Operations screen.
//  CRUD for inventory movements (transfers, replenishments, vendor returns).
//

import SwiftUI

@Observable
final class InventoryOpsViewModel {

    private let dataStore: DataStore
    private let storeId: UUID

    var isLoading = false
    var errorMessage: String?

    init(dataStore: DataStore, storeId: UUID) {
        self.dataStore = dataStore
        self.storeId   = storeId
    }

    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchProducts()
            try await dataStore.fetchStockItems(storeId: storeId)
            try await dataStore.fetchInventoryMovements()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Stock Overview
    var stockItems: [StockItem] { dataStore.stockItems.filter { $0.storeId == storeId } }
    var lowStockItems: [StockItem] { stockItems.filter { $0.quantity <= 1 && $0.status == .available } }

    // MARK: - Movements (all types)
    var allMovements: [InventoryMovement] { dataStore.inventoryMovements }

    var transfers: [InventoryMovement] { allMovements.filter { $0.type == .storeTransfer } }
    var replenishments: [InventoryMovement] { allMovements.filter { $0.type == .dcReplenishment } }
    var vendorReturns: [InventoryMovement] { allMovements.filter { $0.type == .vendorReturn } }

    var pendingApprovals: [InventoryMovement] {
        allMovements.filter { $0.status == .requested }
    }

    // MARK: - CRUD
    func createMovement(_ m: InventoryMovement) async throws {
        try await dataStore.createInventoryMovement(m)
    }

    func approveMovement(_ m: InventoryMovement) async throws {
        // Create an updated version with approved status
        let updated = InventoryMovement(
            id: m.id, type: m.type, sourceId: m.sourceId, destinationId: m.destinationId,
            status: .approved, requestedBy: m.requestedBy, approvedBy: m.approvedBy,
            requestedAt: m.requestedAt, shippedAt: m.shippedAt, receivedAt: m.receivedAt,
            asnNumber: m.asnNumber, itemsExpected: m.itemsExpected, itemsReceived: m.itemsReceived,
            reason: m.reason, notes: m.notes
        )
        try await dataStore.updateInventoryMovement(updated)
        dataStore.logAudit(storeId: storeId, action: "Movement Approved", entityType: "InventoryMovement", entityId: m.id, performedBy: m.approvedBy ?? UUID())
    }

    func rejectMovement(id: UUID) async throws {
        try await dataStore.deleteInventoryMovement(id: id)
    }

    // MARK: - Helpers
    func productName(for id: UUID) -> String { dataStore.productName(for: id) }
    func userName(for id: UUID) -> String { dataStore.userName(for: id) }

    func movementStatusColor(_ status: MovementStatus) -> Color {
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
}
