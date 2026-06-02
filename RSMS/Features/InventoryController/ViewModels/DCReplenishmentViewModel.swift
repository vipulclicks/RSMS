//
//  DCReplenishmentViewModel.swift
//  RSMS
//
//  ViewModel for the DC-to-Store Replenishment screen.
//  Manages dc_replenishment movements, KPIs, and shipment detail state.
//

import SwiftUI

@Observable
final class DCReplenishmentViewModel {

    // MARK: - Data
    var movements: [InventoryMovement] = []
    var movementItemsCache: [UUID: [MovementItem]] = [:]
    var products: [Product] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Detail state
    var selectedShipment: InventoryMovement? = nil
    var selectedLineItems: [DCLineItem] = []
    var isLoadingDetail = false

    // MARK: - Exception form
    var showExceptionSheet = false
    var exceptionNotes: String = ""
    var isSubmittingException = false

    // MARK: - Filtered Lists

    private var dcMovements: [InventoryMovement] {
        movements.filter { $0.type == .dcReplenishment }
    }

    /// Shipments ready to be received (in-transit or approved).
    var pendingShipments: [InventoryMovement] {
        dcMovements
            .filter { $0.status == .inTransit || $0.status == .approved }
            .sorted { ($0.shippedAt ?? .distantPast) > ($1.shippedAt ?? .distantPast) }
    }

    /// Shipments that have been received or completed.
    var recentReceipts: [InventoryMovement] {
        dcMovements
            .filter { $0.status == .received || $0.status == .completed || $0.status == .partial }
            .sorted { ($0.receivedAt ?? .distantPast) > ($1.receivedAt ?? .distantPast) }
    }

    /// All DC replenishments for history.
    var allShipments: [InventoryMovement] {
        dcMovements.sorted { ($0.shippedAt ?? $0.requestedAt ?? .distantPast) > ($1.shippedAt ?? $1.requestedAt ?? .distantPast) }
    }

    // MARK: - KPIs

    var totalIncoming: Int {
        dcMovements.count
    }

    var inTransitCount: Int {
        dcMovements.filter { $0.status == .inTransit }.count
    }

    var receivedCount: Int {
        dcMovements.filter { $0.status == .received || $0.status == .completed }.count
    }

    var partialCount: Int {
        dcMovements.filter { $0.status == .partial }.count
    }

    var exceptionCount: Int {
        dcMovements.filter { $0.status == .exception }.count
    }

    var itemsExpectedToday: Int {
        let cal = Calendar.current
        return dcMovements
            .filter { $0.status == .inTransit }
            .filter { m in
                guard let shipped = m.shippedAt else { return false }
                // Consider shipments shipped in the last 3 days as "expected today"
                return cal.isDateInToday(shipped) ||
                       shipped < Date.now && shipped > cal.date(byAdding: .day, value: -3, to: .now)!
            }
            .reduce(0) { $0 + ($1.itemsExpected ?? 0) }
    }

    var completedThisWeek: Int {
        let cal = Calendar.current
        let weekAgo = cal.date(byAdding: .day, value: -7, to: .now)!
        return dcMovements
            .filter { ($0.status == .received || $0.status == .completed) }
            .filter { ($0.receivedAt ?? .distantPast) > weekAgo }
            .count
    }

    /// Fraction of DC shipments that have been received (for the progress ring).
    var receiptCompletionPercent: Double {
        guard totalIncoming > 0 else { return 0 }
        return Double(receivedCount) / Double(totalIncoming)
    }

    // MARK: - Load

    func load(dataStore: DataStore, storeId: UUID?) async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchInventoryMovements(type: .dcReplenishment)
            try await dataStore.fetchProducts()

            products = dataStore.products

            // Filter movements destined for this store
            if let storeId {
                let storeIdString = storeId.uuidString.lowercased()
                movements = dataStore.inventoryMovements.filter {
                    $0.type == .dcReplenishment &&
                    $0.destinationId.lowercased() == storeIdString
                }
            } else {
                movements = dataStore.inventoryMovements.filter { $0.type == .dcReplenishment }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Load Shipment Detail

    @MainActor
    func loadShipmentDetail(movement: InventoryMovement, dataStore: DataStore) async {
        selectedShipment = movement
        isLoadingDetail = true

        // Fetch line items for this movement
        try? await dataStore.fetchMovementItems(movementId: movement.id)

        // Ensure products are loaded
        if products.isEmpty {
            try? await dataStore.fetchProducts()
            products = dataStore.products
        }

        // Build UI-friendly line items
        selectedLineItems = dataStore.movementItems
            .filter { $0.movementId == movement.id }
            .compactMap { item in
                guard let product = dataStore.product(by: item.productId) else { return nil }
                return DCLineItem(
                    id: item.id,
                    movementItemId: item.id,
                    product: product,
                    expectedQty: item.quantity,
                    receivedQty: nil
                )
            }

        // Cache
        movementItemsCache[movement.id] = dataStore.movementItems.filter { $0.movementId == movement.id }

        isLoadingDetail = false
    }

    // MARK: - Report Exception

    @MainActor
    func reportException(dataStore: DataStore, user: UserProfile, storeId: UUID) async {
        guard let movement = selectedShipment else { return }
        isSubmittingException = true

        let updated = InventoryMovement(
            id: movement.id,
            type: movement.type,
            sourceId: movement.sourceId,
            destinationId: movement.destinationId,
            status: .exception,
            requestedBy: movement.requestedBy,
            approvedBy: movement.approvedBy,
            requestedAt: movement.requestedAt,
            shippedAt: movement.shippedAt,
            receivedAt: movement.receivedAt,
            asnNumber: movement.asnNumber,
            itemsExpected: movement.itemsExpected,
            itemsReceived: movement.itemsReceived,
            reason: movement.reason,
            notes: [movement.notes, "[EXCEPTION] \(exceptionNotes)"].compactMap { $0 }.joined(separator: " — ")
        )

        try? await dataStore.updateInventoryMovement(updated)

        // Update local cache
        if let idx = movements.firstIndex(where: { $0.id == movement.id }) {
            movements[idx] = updated
        }
        selectedShipment = updated

        // Audit trail
        dataStore.logAudit(
            storeId: storeId,
            action: "DC Replenishment — Exception Reported",
            entityType: "InventoryMovement",
            entityId: movement.id,
            performedBy: user.id,
            details: "ASN: \(movement.asnNumber ?? "—") | Notes: \(exceptionNotes)"
        )

        isSubmittingException = false
        showExceptionSheet = false
        exceptionNotes = ""
    }

    // MARK: - Reset

    func resetDetail() {
        selectedShipment = nil
        selectedLineItems = []
        exceptionNotes = ""
    }
}

// MARK: - DC Line Item (UI wrapper)

struct DCLineItem: Identifiable {
    let id: UUID
    let movementItemId: UUID
    let product: Product
    let expectedQty: Int
    let receivedQty: Int?
}
