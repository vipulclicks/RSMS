//
//  VendorReturnViewModel.swift
//  RSMS
//
//  ViewModel for managing Vendor Returns.
//  Handles returning defective, damaged, or overstock items to external vendors.
//

import SwiftUI

@Observable
final class VendorReturnViewModel {

    // MARK: - Data
    var movements: [InventoryMovement] = []
    var movementItemsCache: [UUID: [MovementItem]] = [:]
    var products: [Product] = []
    var stockItems: [StockItem] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Form State
    var showCreateSheet = false
    var returnId: String = ""
    var sourceStore: Store?
    var selectedVendor: String = "VEND-MAISON-001" // Default
    
    // Hardcoded vendors for UI since we don't have a Vendor model
    let vendors = [
        "VEND-MAISON-001",
        "VEND-LUMIERE-HQ",
        "VEND-EXT-042"
    ]

    var returnReasonType: ReturnReason = .defective
    var selectedProduct: Product?
    var quantity: Int = 1
    var returnCart: [ReturnCartItem] = []
    var returnNotes: String = ""
    var productSearchText: String = ""
    
    var isSubmitting = false
    var showSuccess = false

    // MARK: - Detail State
    var selectedReturn: InventoryMovement? = nil
    var selectedLineItems: [ReturnLineItem] = []
    var isLoadingDetail = false
    var isUpdatingStatus = false

    // MARK: - Filtered Lists

    private var vendorReturns: [InventoryMovement] {
        movements.filter { $0.type == .vendorReturn }
    }

    var activeReturns: [InventoryMovement] {
        vendorReturns
            .filter { $0.status == .requested || $0.status == .approved || $0.status == .inTransit }
            .sorted { ($0.requestedAt ?? .distantPast) > ($1.requestedAt ?? .distantPast) }
    }

    var recentReturns: [InventoryMovement] {
        vendorReturns
            .filter { $0.status == .completed || $0.status == .cancelled }
            .sorted { ($0.receivedAt ?? $0.shippedAt ?? $0.requestedAt ?? .distantPast) > ($1.receivedAt ?? $1.shippedAt ?? $1.requestedAt ?? .distantPast) }
    }

    var searchResults: [Product] {
        guard !productSearchText.isEmpty else { return [] }
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(productSearchText) ||
            $0.sku.localizedCaseInsensitiveContains(productSearchText)
        }
    }

    // MARK: - KPIs

    var totalReturns: Int {
        vendorReturns.count
    }

    var pendingCount: Int {
        vendorReturns.filter { $0.status == .requested || $0.status == .approved }.count
    }

    var shippedCount: Int {
        vendorReturns.filter { $0.status == .inTransit }.count
    }

    var completedCount: Int {
        vendorReturns.filter { $0.status == .completed }.count
    }
    
    var totalValueReturned: Double {
        // Approximate based on items expected * average price (for simplicity without joining all line items)
        // In a real app we'd sum line items.
        return 0.0 // Placeholder or we compute it if needed
    }

    // Available stock for selected product at source
    var availableStock: Int {
        guard let product = selectedProduct else { return 0 }
        return stockForProduct(product)
    }

    func stockForProduct(_ product: Product) -> Int {
        let storeId = sourceStore?.id
        return stockItems
            .filter { $0.productId == product.id && $0.status == .available && (storeId == nil || $0.storeId == storeId) }
            .reduce(0) { $0 + $1.quantity }
    }

    // MARK: - Load

    func load(dataStore: DataStore, storeId: UUID?) async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchProducts()
            try await dataStore.fetchStockItems()
            try await dataStore.fetchInventoryMovements(type: .vendorReturn)

            products = dataStore.products
            stockItems = dataStore.stockItems
            
            if let storeId {
                let storeIdString = storeId.uuidString.lowercased()
                movements = dataStore.inventoryMovements.filter {
                    $0.type == .vendorReturn &&
                    $0.sourceId.lowercased() == storeIdString
                }
                sourceStore = dataStore.stores.first(where: { $0.id == storeId }) ?? Store.preview
            } else {
                movements = dataStore.inventoryMovements.filter { $0.type == .vendorReturn }
                sourceStore = Store.preview
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Generate Return ID

    func generateReturnID() {
        let digits = String(format: "%04d", Int.random(in: 1000...9999))
        returnId = "RTV-\(digits)"
    }

    // MARK: - Reset Form

    func resetForm() {
        generateReturnID()
        selectedProduct = nil
        quantity = 1
        returnCart = []
        returnReasonType = .defective
        returnNotes = ""
        productSearchText = ""
    }

    // MARK: - Submit Return

    func submitReturn(dataStore: DataStore, requestedBy: UUID?) async {
        guard let src = sourceStore, !returnCart.isEmpty else { return }

        isSubmitting = true
        let typeTag = "[\(returnReasonType.rawValue.uppercased())]"
        let notes = [typeTag, returnId, returnNotes].filter { !$0.isEmpty }.joined(separator: " — ")

        let totalItems = returnCart.reduce(0) { $0 + $1.quantity }
        let uniqueProducts = returnCart.count
        let reasonTitle = uniqueProducts == 1 ? "Vendor Return — \(returnCart[0].product.name)" : "Vendor Return — \(uniqueProducts) products"

        let movement = InventoryMovement(
            id: UUID(),
            type: .vendorReturn,
            sourceId: src.id.uuidString,
            destinationId: selectedVendor,
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
            for cartItem in returnCart {
                let item = MovementItem(
                    id: UUID(),
                    movementId: created.id,
                    productId: cartItem.product.id,
                    quantity: cartItem.quantity,
                    reason: cartItem.reason.rawValue
                )
                try await dataStore.createMovementItem(item)
            }

            // Audit trail
            dataStore.logAudit(
                storeId: src.id,
                action: "Vendor Return Requested",
                entityType: "InventoryMovement",
                entityId: created.id,
                performedBy: requestedBy ?? UUID(),
                details: "Return to \(selectedVendor): \(totalItems) items. Reason: \(returnReasonType.rawValue)"
            )

            // Show success overlay temporarily
            withAnimation {
                showCreateSheet = false
                showSuccess = true
            }

            try await Task.sleep(nanoseconds: 2_000_000_000)

            withAnimation {
                showSuccess = false
            }

        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }

    // MARK: - Load Detail

    @MainActor
    func loadReturnDetail(movement: InventoryMovement, dataStore: DataStore) async {
        selectedReturn = movement
        isLoadingDetail = true

        try? await dataStore.fetchMovementItems(movementId: movement.id)

        if products.isEmpty {
            try? await dataStore.fetchProducts()
            products = dataStore.products
        }

        selectedLineItems = dataStore.movementItems
            .filter { $0.movementId == movement.id }
            .compactMap { item in
                guard let product = dataStore.product(by: item.productId) else { return nil }
                return ReturnLineItem(
                    id: item.id,
                    product: product,
                    quantity: item.quantity,
                    reason: item.reason ?? "N/A"
                )
            }

        movementItemsCache[movement.id] = dataStore.movementItems.filter { $0.movementId == movement.id }

        isLoadingDetail = false
    }
    
    // MARK: - Update Status
    
    @MainActor
    func updateStatus(to newStatus: MovementStatus, dataStore: DataStore, user: UserProfile, storeId: UUID) async {
        guard let movement = selectedReturn else { return }
        isUpdatingStatus = true
        
        let updated = InventoryMovement(
            id: movement.id,
            type: movement.type,
            sourceId: movement.sourceId,
            destinationId: movement.destinationId,
            status: newStatus,
            requestedBy: movement.requestedBy,
            approvedBy: movement.approvedBy,
            requestedAt: movement.requestedAt,
            shippedAt: newStatus == .inTransit ? .now : movement.shippedAt,
            receivedAt: newStatus == .completed ? .now : movement.receivedAt,
            asnNumber: movement.asnNumber,
            itemsExpected: movement.itemsExpected,
            itemsReceived: newStatus == .completed ? movement.itemsExpected : movement.itemsReceived,
            reason: movement.reason,
            notes: movement.notes
        )
        
        try? await dataStore.updateInventoryMovement(updated)
        
        if let idx = movements.firstIndex(where: { $0.id == movement.id }) {
            movements[idx] = updated
        }
        selectedReturn = updated
        
        dataStore.logAudit(
            storeId: storeId,
            action: "Vendor Return Status Updated",
            entityType: "InventoryMovement",
            entityId: movement.id,
            performedBy: user.id,
            details: "Status changed to \(newStatus.rawValue)"
        )
        
        isUpdatingStatus = false
    }
}

// MARK: - Supporting Types

enum ReturnReason: String, CaseIterable, Identifiable {
    case defective = "Defective"
    case damage = "Damaged in Transit"
    case overstock = "Overstock"
    case recall = "Recall"
    
    var id: String { rawValue }
}

struct ReturnCartItem: Identifiable {
    let id = UUID()
    let product: Product
    var quantity: Int
    var reason: ReturnReason
}

struct ReturnLineItem: Identifiable {
    let id: UUID
    let product: Product
    let quantity: Int
    let reason: String
}
