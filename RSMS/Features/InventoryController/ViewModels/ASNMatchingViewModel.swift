//
//  ASNMatchingViewModel.swift
//  RSMS
//
//  Business logic for receiving inventory against an Advanced Shipment Notice (ASN).
//  Searches inventory_movements by asn_number, presents line items from movement_items,
//  and writes stock updates, variance records, and an audit trail entry to Supabase.
//

import SwiftUI
import Observation

// MARK: - ASN Match State

enum ASNMatchState: Equatable {
    case idle
    case notFound
    case matched
    case confirmed
    case error(String)

    static func == (lhs: ASNMatchState, rhs: ASNMatchState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.notFound, .notFound), (.matched, .matched), (.confirmed, .confirmed): return true
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - ASN Line Item (UI-friendly wrapper)

struct ASNLineItem: Identifiable {
    let id: UUID            // movementItem.id
    let movementItemId: UUID
    let product: Product
    let expectedQty: Int
}

// MARK: - ViewModel

@Observable
final class ASNMatchingViewModel {

    // MARK: - Search state
    var asnQuery: String = ""
    var state: ASNMatchState = .idle
    var isSubmitting: Bool = false

    // MARK: - Matched data (from Supabase)
    var matchedMovement: InventoryMovement? = nil
    var lineItems: [ASNLineItem] = []

    // MARK: - User inputs: movementItemId → quantity received
    var receivedQtys: [UUID: Int] = [:]

    // MARK: - Confirm result
    var totalReceived: Int = 0
    var totalExpected: Int = 0
    var varianceCount: Int = 0

    // MARK: - Search

    /// Synchronous search against cached inventory_movements (already fetched by StockInHubView).
    func search(in dataStore: DataStore, storeId: UUID) {
        let query = asnQuery.trimmingCharacters(in: .whitespaces).uppercased()
        guard !query.isEmpty else { return }

        let storeIdLower = storeId.uuidString.lowercased()

        // 1. Exact match: ASN + store + in_transit
        var match = dataStore.inventoryMovements.first { movement in
            guard let asn = movement.asnNumber else { return false }
            return asn.uppercased() == query &&
                   movement.destinationId.lowercased() == storeIdLower &&
                   movement.status == .inTransit
        }

        // 2. Fallback: ASN + store, any status
        if match == nil {
            match = dataStore.inventoryMovements.first { movement in
                guard let asn = movement.asnNumber else { return false }
                return asn.uppercased() == query &&
                       movement.destinationId.lowercased() == storeIdLower
            }
        }

        // 3. Last resort: ASN number only (ignore store filter)
        if match == nil {
            match = dataStore.inventoryMovements.first { movement in
                guard let asn = movement.asnNumber else { return false }
                return asn.uppercased() == query
            }
        }

        guard let movement = match else {
            state = .notFound
            return
        }

        matchedMovement = movement

        // Build line items from cached movement_items
        lineItems = dataStore.movementItems
            .filter { $0.movementId == movement.id }
            .compactMap { item in
                guard let product = dataStore.product(by: item.productId) else { return nil }
                return ASNLineItem(
                    id: item.id,
                    movementItemId: item.id,
                    product: product,
                    expectedQty: item.quantity
                )
            }

        // Pre-fill received quantities with expected (optimistic)
        receivedQtys = Dictionary(uniqueKeysWithValues: lineItems.map { ($0.id, $0.expectedQty) })

        state = .matched
    }

    /// Fetches movements from Supabase, then fetches line items for the matched movement, then searches.
    @MainActor
    func fetchAndSearch(in dataStore: DataStore, storeId: UUID) async {
        let query = asnQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        // 1. Always re-fetch movements fresh from Supabase
        try? await dataStore.fetchInventoryMovements()

        // 2. Fetch products if not cached
        if dataStore.products.isEmpty {
            try? await dataStore.fetchProducts()
        }

        // 3. Find the movement — try progressively looser matches
        let queryUpper = query.uppercased()
        let storeIdLower = storeId.uuidString.lowercased()

        // First: exact match (ASN + store + in_transit)
        var matchedMovement = dataStore.inventoryMovements.first(where: {
            $0.asnNumber?.uppercased() == queryUpper &&
            $0.destinationId.lowercased() == storeIdLower &&
            $0.status == .inTransit
        })

        // Fallback 1: ASN + store, ignore status (maybe status decoding issue)
        if matchedMovement == nil {
            matchedMovement = dataStore.inventoryMovements.first(where: {
                $0.asnNumber?.uppercased() == queryUpper &&
                $0.destinationId.lowercased() == storeIdLower
            })
        }

        // Fallback 2: ASN only, ignore store (for demo/testing across stores)
        if matchedMovement == nil {
            matchedMovement = dataStore.inventoryMovements.first(where: {
                $0.asnNumber?.uppercased() == queryUpper
            })
        }

        // 4. If we found a movement, always fetch its line items fresh
        if let movement = matchedMovement {
            try? await dataStore.fetchMovementItems(movementId: movement.id)
        }

        search(in: dataStore, storeId: storeId)
    }

    // MARK: - Receive Shipment

    /// Writes all stock updates, variances, movement status, and audit trail to Supabase.
    @MainActor
    func receive(dataStore: DataStore, user: UserProfile, storeId: UUID) async {
        guard let movement = matchedMovement else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        var totalRec = 0
        var varCount = 0

        for lineItem in lineItems {
            let receivedQty = receivedQtys[lineItem.id] ?? 0
            totalRec += receivedQty

            // 1. Update stock_items quantity for this product at this store
            if let existing = dataStore.stockItems.first(where: {
                $0.productId == lineItem.product.id && $0.storeId == storeId
            }) {
                let updated = StockItem(
                    id: existing.id,
                    productId: existing.productId,
                    storeId: existing.storeId,
                    quantity: existing.quantity + receivedQty,
                    rfidTag: existing.rfidTag,
                    location: existing.location,
                    status: .available,
                    lastScannedAt: .now,
                    updatedAt: .now
                )
                try? await dataStore.updateStockItem(updated)
            }

            // 2. Create variance if received ≠ expected
            if receivedQty != lineItem.expectedQty {
                varCount += 1
                let variance = InventoryVariance(
                    id: UUID(),
                    storeId: storeId,
                    productId: lineItem.product.id,
                    expectedQty: lineItem.expectedQty,
                    actualQty: receivedQty,
                    variance: receivedQty - lineItem.expectedQty,
                    reportedBy: user.id,
                    status: .open,
                    cycleCountId: nil,
                    resolution: nil,
                    reportedAt: .now,
                    resolvedAt: nil
                )
                try? await dataStore.createInventoryVariance(variance)
            }
        }

        // 3. Mark movement as received
        let updatedMovement = InventoryMovement(
            id: movement.id,
            type: movement.type,
            sourceId: movement.sourceId,
            destinationId: movement.destinationId,
            status: varCount > 0 ? .partial : .received,
            requestedBy: movement.requestedBy,
            approvedBy: movement.approvedBy,
            requestedAt: movement.requestedAt,
            shippedAt: movement.shippedAt,
            receivedAt: .now,
            asnNumber: movement.asnNumber,
            itemsExpected: movement.itemsExpected,
            itemsReceived: totalRec,
            reason: movement.reason,
            notes: movement.notes
        )
        try? await dataStore.updateInventoryMovement(updatedMovement)

        // 4. Write audit trail
        let details = "ASN: \(movement.asnNumber ?? "—") | Received: \(totalRec)/\(movement.itemsExpected ?? 0) | Variances: \(varCount)"
        dataStore.logAudit(
            storeId: storeId,
            action: "ASN Match — \(movement.type == .dcReplenishment ? "DC Replenishment" : "Store Transfer")",
            entityType: "InventoryMovement",
            entityId: movement.id,
            performedBy: user.id,
            details: details
        )

        totalReceived = totalRec
        totalExpected = movement.itemsExpected ?? lineItems.reduce(0) { $0 + $1.expectedQty }
        varianceCount = varCount
        state = .confirmed
    }

    // MARK: - Reset

    func reset() {
        asnQuery = ""
        matchedMovement = nil
        lineItems = []
        receivedQtys = [:]
        totalReceived = 0
        totalExpected = 0
        varianceCount = 0
        state = .idle
    }
}
