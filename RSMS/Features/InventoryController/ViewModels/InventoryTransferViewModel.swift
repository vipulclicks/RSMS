//
//  InventoryTransferViewModel.swift
//  RSMS
//
//  ViewModel for the Inventory Transfer screen.
//  Manages store-transfer movements, form state, and KPIs.
//

import SwiftUI

struct TransferItem: Identifiable, Equatable {
    let id = UUID()
    let product: Product
    var quantity: Int
}

@Observable
final class InventoryTransferViewModel {

    // MARK: - Data
    var movements: [InventoryMovement] = []
    var movementItemsCache: [UUID: [MovementItem]] = [:]
    var stores: [Store] = []
    var products: [Product] = []
    var stockItems: [StockItem] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Create Form State
    var showCreateSheet = false
    var transferId: String = ""
    var sourceStore: Store?
    var destinationStore: Store?
    var selectedProduct: Product?
    var quantity: Int = 1
    var transferCart: [TransferItem] = []
    var priority: TransferPriority = .medium
    var expectedDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: .now)!
    var transferNotes: String = ""
    var isSubmitting = false
    var showSuccess = false

    // MARK: - Search
    var productSearchText = ""
    var searchResults: [Product] {
        guard !productSearchText.isEmpty else { return [] }
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(productSearchText) ||
            $0.sku.localizedCaseInsensitiveContains(productSearchText)
        }.prefix(8).map { $0 }
    }

    // MARK: - KPIs

    private var storeTransfers: [InventoryMovement] {
        movements.filter { $0.type == .storeTransfer }
    }

    var todayTransfers: Int {
        let cal = Calendar.current
        return storeTransfers.filter { m in
            guard let date = m.requestedAt else { return false }
            return cal.isDateInToday(date)
        }.count
    }

    var pendingCount: Int {
        storeTransfers.filter { $0.status == .requested || $0.status == .approved }.count
    }

    var inTransitCount: Int {
        storeTransfers.filter { $0.status == .inTransit }.count
    }

    var completedCount: Int {
        storeTransfers.filter { $0.status == .completed || $0.status == .received }.count
    }

    var urgentCount: Int {
        storeTransfers.filter { m in
            (m.notes ?? "").localizedCaseInsensitiveContains("[URGENT]") ||
            (m.notes ?? "").localizedCaseInsensitiveContains("[HIGH]")
        }.count
    }

    var approvalPendingCount: Int {
        storeTransfers.filter { $0.status == .requested }.count
    }

    var delayedCount: Int {
        storeTransfers.filter { $0.status == .inTransit }.count // Simplified: all in-transit as potential delays
    }

    // MARK: - Sorted transfers for feed
    var recentTransfers: [InventoryMovement] {
        storeTransfers.sorted { (a, b) in
            (a.requestedAt ?? .distantPast) > (b.requestedAt ?? .distantPast)
        }
    }

    // MARK: - Availability rows
    struct AvailabilityRow: Identifiable {
        let id: UUID
        let product: Product
        let sourceStock: Int
        let destStock: Int
        let recommendedQty: Int
        var isLowStock: Bool { sourceStock <= 2 }
    }

    var availabilityRows: [AvailabilityRow] {
        guard let src = sourceStore, let dst = destinationStore else {
            // Default: show all products with stock from current store
            return products.prefix(10).map { product in
                let srcQty = stockItems
                    .filter { $0.productId == product.id && $0.status == .available }
                    .reduce(0) { $0 + $1.quantity }
                return AvailabilityRow(
                    id: product.id,
                    product: product,
                    sourceStock: srcQty,
                    destStock: 0,
                    recommendedQty: max(0, srcQty > 2 ? 1 : 0)
                )
            }
        }

        return products.prefix(10).map { product in
            let srcQty = stockItems
                .filter { $0.productId == product.id && $0.storeId == src.id && $0.status == .available }
                .reduce(0) { $0 + $1.quantity }
            let dstQty = stockItems
                .filter { $0.productId == product.id && $0.storeId == dst.id && $0.status == .available }
                .reduce(0) { $0 + $1.quantity }
            let recommended = dstQty < 2 && srcQty > 2 ? min(2, srcQty - 1) : 0

            return AvailabilityRow(
                id: product.id,
                product: product,
                sourceStock: srcQty,
                destStock: dstQty,
                recommendedQty: recommended
            )
        }
    }

    // Available stock for selected product at source
    var availableStock: Int {
        guard let product = selectedProduct else { return 0 }
        return stockForProduct(product)
    }

    // Helper to get stock for any given product
    func stockForProduct(_ product: Product) -> Int {
        let storeId = sourceStore?.id
        return stockItems
            .filter { $0.productId == product.id && $0.status == .available && (storeId == nil || $0.storeId == storeId) }
            .reduce(0) { $0 + $1.quantity }
    }

    // Completion % for progress bar
    var completionPercent: Double {
        let total = storeTransfers.count
        guard total > 0 else { return 0 }
        return Double(completedCount) / Double(total)
    }

    // MARK: - Load

    func load(dataStore: DataStore, storeId: UUID?) async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchStores()
            try await dataStore.fetchProducts()
            try await dataStore.fetchStockItems()
            try await dataStore.fetchInventoryMovements(type: .storeTransfer)

            stores = dataStore.stores
            products = dataStore.products
            stockItems = dataStore.stockItems
            movements = dataStore.inventoryMovements
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Generate Transfer ID

    func generateTransferID() {
        let digits = String(format: "%04d", Int.random(in: 1000...9999))
        transferId = "TRF-\(digits)"
    }

    // MARK: - Reset Form

    func resetForm() {
        generateTransferID()
        sourceStore = stores.first
        destinationStore = stores.count > 1 ? stores[1] : nil
        selectedProduct = nil
        quantity = 1
        transferCart = []
        priority = .medium
        expectedDate = Calendar.current.date(byAdding: .day, value: 3, to: .now)!
        transferNotes = ""
        productSearchText = ""
    }

    // MARK: - Submit Transfer

    func submitTransfer(dataStore: DataStore, requestedBy: UUID?) async {
        guard let src = sourceStore, let dst = destinationStore, !transferCart.isEmpty else { return }

        isSubmitting = true
        let priorityTag = "[\(priority.rawValue.uppercased())]"
        let notes = [priorityTag, transferId, transferNotes].filter { !$0.isEmpty }.joined(separator: " — ")

        let totalItems = transferCart.reduce(0) { $0 + $1.quantity }
        let uniqueProducts = transferCart.count
        let reasonTitle = uniqueProducts == 1 ? "Store Transfer — \(transferCart[0].product.name)" : "Store Transfer — \(uniqueProducts) products"

        let movement = InventoryMovement(
            id: UUID(),
            type: .storeTransfer,
            sourceId: src.id.uuidString,
            destinationId: dst.id.uuidString,
            status: .requested,
            requestedBy: requestedBy,
            approvedBy: nil,
            requestedAt: .now,
            shippedAt: nil,
            receivedAt: nil,
            asnNumber: nil,
            itemsExpected: totalItems,
            itemsReceived: nil,
            reason: reasonTitle,
            notes: notes
        )

        do {
            let created = try await dataStore.createInventoryMovement(movement)
            movements.append(created)

            // Create movement items for each item in the cart
            for cartItem in transferCart {
                let item = MovementItem(
                    id: UUID(),
                    movementId: created.id,
                    productId: cartItem.product.id,
                    quantity: cartItem.quantity,
                    reason: nil
                )
                _ = try await dataStore.createMovementItem(item)
            }

            withAnimation(.spring()) {
                showSuccess = true
            }
            showCreateSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}

// MARK: - Transfer Priority

enum TransferPriority: String, CaseIterable, Identifiable {
    case low     = "Low"
    case medium  = "Medium"
    case high    = "High"
    case urgent  = "Urgent"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .low:    return RSMSTheme.success
        case .medium: return RSMSTheme.info
        case .high:   return RSMSTheme.warning
        case .urgent: return RSMSTheme.danger
        }
    }

    var icon: String {
        switch self {
        case .low:    return "arrow.down"
        case .medium: return "minus"
        case .high:   return "arrow.up"
        case .urgent: return "exclamationmark.2"
        }
    }
}
