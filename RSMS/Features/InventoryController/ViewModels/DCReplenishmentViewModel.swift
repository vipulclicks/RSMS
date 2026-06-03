//
//  DCReplenishmentViewModel.swift
//  RSMS
//

import SwiftUI

@Observable
final class DCReplenishmentViewModel {

    // MARK: - Data
    var movements: [InventoryMovement] = []
    var stores: [Store] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - KPIs
    private var dcReplenishments: [InventoryMovement] {
        movements.filter { $0.type == .dcReplenishment }
    }

    var pendingCount: Int {
        dcReplenishments.filter { $0.status == .requested || $0.status == .approved }.count
    }

    var inTransitCount: Int {
        dcReplenishments.filter { $0.status == .inTransit }.count
    }

    var completedCount: Int {
        dcReplenishments.filter { $0.status == .completed || $0.status == .received }.count
    }

    var delayedCount: Int {
        // Simplified metric: just all in transit for now, or could compare shippedAt date
        dcReplenishments.filter { $0.status == .inTransit }.count
    }
    
    var partialCount: Int {
        dcReplenishments.filter { $0.status == .partial }.count
    }

    // MARK: - Sorted for Feed
    var recentReplenishments: [InventoryMovement] {
        dcReplenishments.sorted { (a, b) in
            // Sort by shippedAt descending, fallback to requestedAt
            let dateA = a.shippedAt ?? a.requestedAt ?? .distantPast
            let dateB = b.shippedAt ?? b.requestedAt ?? .distantPast
            return dateA > dateB
        }
    }

    // MARK: - Load
    func load(dataStore: DataStore, storeId: UUID?) async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchStores()
            // We want to fetch replenishments heading to THIS store or all if admin
            // For now, we fetch all to match inventory dashboard, then filter locally
            try await dataStore.fetchInventoryMovements(type: .dcReplenishment)
            
            self.stores = dataStore.stores
            self.movements = dataStore.inventoryMovements
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Helpers
    func sourceName(for movement: InventoryMovement) -> String {
        // Source is usually a string like "DC-EUROPE-01" or a Store UUID
        if let uuid = UUID(uuidString: movement.sourceId), let store = stores.first(where: { $0.id == uuid }) {
            return store.name
        }
        return movement.sourceId
    }

    func destinationName(for movement: InventoryMovement) -> String {
        if let uuid = UUID(uuidString: movement.destinationId), let store = stores.first(where: { $0.id == uuid }) {
            return store.name
        }
        return movement.destinationId
    }
    
    // MARK: - Receive Action
    func markAsReceived(movement: InventoryMovement, dataStore: DataStore, userId: UUID?, storeId: UUID?) async {
        let updatedMovement = InventoryMovement(
            id: movement.id,
            type: movement.type,
            sourceId: movement.sourceId,
            destinationId: movement.destinationId,
            status: .received,
            requestedBy: movement.requestedBy,
            approvedBy: movement.approvedBy,
            requestedAt: movement.requestedAt,
            shippedAt: movement.shippedAt,
            receivedAt: .now,
            asnNumber: movement.asnNumber,
            itemsExpected: movement.itemsExpected,
            itemsReceived: movement.itemsExpected, // Assume full receipt for simple action
            reason: movement.reason,
            notes: movement.notes
        )
        
        do {
            try await dataStore.updateInventoryMovement(updatedMovement)
            if let index = movements.firstIndex(where: { $0.id == movement.id }) {
                withAnimation(.spring()) {
                    movements[index] = updatedMovement
                }
            }
            
            // Log to Audit Trail
            if let storeId = storeId {
                let details = "Received \(movement.itemsExpected ?? 0) items from \(movement.sourceId)."
                let uid = userId ?? UUID()
                dataStore.logAudit(storeId: storeId, action: "Replenishment Received", entityType: "InventoryMovement", entityId: movement.id, performedBy: uid, details: details)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Mock State for Detail View
struct DCLineItem: Identifiable, Equatable {
    let id = UUID()
    let product: Product
    let expectedQty: Int
}

extension DCReplenishmentViewModel {
    // These properties are required by DCShipmentDetailView
    // Since InventoryMovement items are not yet fully implemented in Supabase schema, we mock them
    var selectedLineItems: [DCLineItem] {
        get { return [] }
        set { }
    }
    
    var showExceptionSheet: Bool {
        get { return false }
        set { }
    }
    
    var exceptionNotes: String {
        get { return "" }
        set { }
    }
    
    var isSubmittingException: Bool {
        return false
    }
    
    var isLoadingDetail: Bool {
        return false
    }
    
    func loadShipmentDetail(movement: InventoryMovement, dataStore: DataStore) async {
        // No-op for now
    }
    
    func reportException(dataStore: DataStore, user: UserProfile, storeId: UUID) async {
        // No-op for now
    }
}
