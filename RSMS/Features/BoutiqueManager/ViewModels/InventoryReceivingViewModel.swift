//
//  InventoryReceivingViewModel.swift
//  RSMS
//

import SwiftUI

enum ReceivingFeedback {
    case idle
    case success(String)
    case warning(String)
    case error(String)

    var message: String? {
        switch self {
        case .idle: return nil
        case .success(let message), .warning(let message), .error(let message): return message
        }
    }

    var color: Color {
        switch self {
        case .idle:                return RSMSTheme.textTertiary
        case .success:             return RSMSTheme.success
        case .warning:             return RSMSTheme.warning
        case .error:               return RSMSTheme.danger
        }
    }

    var icon: String {
        switch self {
        case .idle:                return "shippingbox"
        case .success:             return "checkmark.circle.fill"
        case .warning:             return "exclamationmark.triangle.fill"
        case .error:               return "xmark.circle.fill"
        }
    }
}

struct ReceivingBatchLine: Identifiable {
    let id = UUID()
    let product: Product
    let existingStockItem: StockItem?
    var quantity: Int
    var location: String
    var rfidTag: String?
}

struct ReceivingCompletionSummary {
    let movement: InventoryMovement
    let totalUnits: Int
    let totalSKUs: Int
    let locations: [String]
}

@Observable
final class InventoryReceivingViewModel {
    var draftItems: [ReceivingBatchLine] = []
    var bulkLocation: String = ""
    var feedback: ReceivingFeedback = .idle
    var isPreloading = false
    var isFinalizing = false
    var completionSummary: ReceivingCompletionSummary?

    var totalUnits: Int {
        draftItems.reduce(0) { $0 + $1.quantity }
    }

    var assignedLocations: [String] {
        Array(
            Set(
                draftItems.compactMap {
                    let trimmed = $0.location.trimmingCharacters(in: .whitespacesAndNewlines)
                    return trimmed.isEmpty ? nil : trimmed
                }
            )
        )
        .sorted()
    }

    @MainActor
    func preload(dataStore: DataStore, storeId: UUID?) async {
        isPreloading = true
        defer { isPreloading = false }

        if dataStore.products.isEmpty {
            try? await dataStore.fetchProducts()
        }

        if let storeId, dataStore.stockItems.isEmpty {
            try? await dataStore.fetchStockItems(storeId: storeId)
        }
    }

    @MainActor
    func process(scannedCode: String, dataStore: DataStore, storeId: UUID?) async {
        let normalized = scannedCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }

        completionSummary = nil

        if dataStore.products.isEmpty {
            try? await dataStore.fetchProducts()
        }

        if let storeId, dataStore.stockItems.isEmpty {
            try? await dataStore.fetchStockItems(storeId: storeId)
        }

        let productMatch = dataStore.products.first {
            $0.sku.caseInsensitiveCompare(normalized) == .orderedSame
        } ?? dataStore.products.first {
            $0.sku.localizedCaseInsensitiveContains(normalized)
        }

        if let productMatch {
            let stockItem = dataStore.stockItems.first {
                $0.productId == productMatch.id && $0.storeId == storeId
            }
            append(product: productMatch, stockItem: stockItem, scannedCode: normalized)
            return
        }

        if let stockItem = dataStore.stockItems.first(where: {
            ($0.rfidTag ?? "").caseInsensitiveCompare(normalized) == .orderedSame &&
            $0.storeId == storeId
        }), let product = dataStore.product(by: stockItem.productId) {
            append(product: product, stockItem: stockItem, scannedCode: normalized)
            return
        }

        feedback = .error("Code not recognized. Scan a known SKU or existing RFID tag.")
    }

    func updateLocation(_ location: String, for lineId: UUID) {
        guard let index = draftItems.firstIndex(where: { $0.id == lineId }) else { return }
        draftItems[index].location = location
    }

    func updateQuantity(_ quantity: Int, for lineId: UUID) {
        guard let index = draftItems.firstIndex(where: { $0.id == lineId }) else { return }
        draftItems[index].quantity = max(quantity, 1)
    }

    func removeLine(id: UUID) {
        draftItems.removeAll { $0.id == id }
        if draftItems.isEmpty {
            feedback = .idle
        }
    }

    func applyBulkLocation() {
        let trimmed = bulkLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            feedback = .warning("Enter a storage location before applying it to the batch.")
            return
        }

        for index in draftItems.indices {
            draftItems[index].location = trimmed
        }
        feedback = .success("Assigned \(trimmed) to all items in the batch.")
    }

    @MainActor
    func finalize(dataStore: DataStore, user: UserProfile) async {
        guard SupabaseClient.shared.accessToken != nil else {
            feedback = .error("No active Supabase session. Sign in with email and password first.")
            return
        }

        guard let storeId = user.storeId else {
            feedback = .error("Missing store context for this user.")
            return
        }

        guard !draftItems.isEmpty else {
            feedback = .warning("Scan at least one item before completing receiving.")
            return
        }

        let missingLocation = draftItems.first { $0.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard missingLocation == nil else {
            feedback = .warning("Assign a storage location to every received item before completing put-away.")
            return
        }

        isFinalizing = true
        defer { isFinalizing = false }

        do {
            let receivedAt = Date()
            let movement = InventoryMovement(
                id: UUID(),
                type: .storeTransfer,
                sourceId: "INBOUND",
                destinationId: storeId.uuidString.lowercased(),
                status: .completed,
                requestedBy: user.id,
                approvedBy: user.id,
                requestedAt: receivedAt,
                shippedAt: receivedAt,
                receivedAt: receivedAt,
                asnNumber: nil,
                itemsExpected: totalUnits,
                itemsReceived: totalUnits,
                reason: "Boutique receiving",
                notes: "Received \(totalUnits) units across \(draftItems.count) SKUs."
            )
            print("[RSMS] inventory_movements insert", [
                "source_id": movement.sourceId,
                "destination_id": movement.destinationId,
                "requested_by": movement.requestedBy?.uuidString ?? "nil",
                "status": movement.status.rawValue,
                "type": movement.type.rawValue
            ])
            let createdMovement: InventoryMovement
            do {
                createdMovement = try await dataStore.createInventoryMovement(movement)
            } catch {
                feedback = .error("Inventory movement insert failed: \(error.localizedDescription)")
                return
            }

            for line in draftItems {
                let movementItem = MovementItem(
                    id: UUID(),
                    movementId: createdMovement.id,
                    productId: line.product.id,
                    quantity: line.quantity,
                    reason: "Put away to \(line.location)"
                )
                do {
                    _ = try await dataStore.createMovementItem(movementItem)
                } catch {
                    feedback = .error("Movement item insert failed: \(error.localizedDescription)")
                    return
                }

                do {
                    _ = try await dataStore.receiveStock(
                        productId: line.product.id,
                        storeId: storeId,
                        quantity: line.quantity,
                        location: line.location,
                        rfidTag: line.rfidTag
                    )
                } catch {
                    feedback = .error("Stock update failed: \(error.localizedDescription)")
                    return
                }
            }

            dataStore.logAudit(
                storeId: storeId,
                action: "Inventory Receiving Completed",
                entityType: "InventoryMovement",
                entityId: createdMovement.id,
                performedBy: user.id,
                details: "Received \(totalUnits) units across \(draftItems.count) SKUs into \(assignedLocations.joined(separator: ", "))."
            )

            completionSummary = ReceivingCompletionSummary(
                movement: createdMovement,
                totalUnits: totalUnits,
                totalSKUs: draftItems.count,
                locations: assignedLocations
            )
            draftItems = []
            feedback = .success("Receiving and put-away completed successfully.")
        } catch {
            feedback = .error(error.localizedDescription)
        }
    }

    func startNewBatch() {
        draftItems = []
        bulkLocation = ""
        completionSummary = nil
        feedback = .idle
    }

    private func append(product: Product, stockItem: StockItem?, scannedCode: String) {
        if let index = draftItems.firstIndex(where: { $0.product.id == product.id }) {
            draftItems[index].quantity += 1
            feedback = .success("Updated \(product.name) to \(draftItems[index].quantity) units.")
            return
        }

        let defaultLocation = stockItem?.location ?? bulkLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedLocation = defaultLocation.isEmpty ? "" : defaultLocation
        let rfidTag = stockItem?.rfidTag?.caseInsensitiveCompare(scannedCode) == .orderedSame ? stockItem?.rfidTag : nil

        draftItems.insert(
            ReceivingBatchLine(
                product: product,
                existingStockItem: stockItem,
                quantity: 1,
                location: resolvedLocation,
                rfidTag: rfidTag
            ),
            at: 0
        )
        feedback = .success("Added \(product.name) to the receiving batch.")
    }
}
