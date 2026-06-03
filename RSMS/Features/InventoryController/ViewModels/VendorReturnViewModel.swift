//
//  VendorReturnViewModel.swift
//  RSMS
//
//  ViewModel for the Vendor Returns screen.
//  Manages vendor-return movements, form state, KPIs, and search.
//  Follows the same @Observable pattern as InventoryTransferViewModel.
//

import SwiftUI

// MARK: - Return Cart Item

struct ReturnItem: Identifiable, Equatable {
    let id = UUID()
    let product: Product
    var quantity: Int
    var reason: ReturnReason
}

// MARK: - Return Reason

enum ReturnReason: String, CaseIterable, Identifiable {
    case defective      = "Defective"
    case damaged        = "Damaged"
    case incorrectItem  = "Incorrect Item"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .defective:      return "exclamationmark.triangle.fill"
        case .damaged:        return "hammer.fill"
        case .incorrectItem:  return "arrow.triangle.swap"
        }
    }

    var color: Color {
        switch self {
        case .defective:      return RSMSTheme.danger
        case .damaged:        return RSMSTheme.warning
        case .incorrectItem:  return RSMSTheme.info
        }
    }
}

// MARK: - Return Priority

enum ReturnPriority: String, CaseIterable, Identifiable {
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

// MARK: - Return Status (for display)

enum VendorReturnStatus: String, CaseIterable {
    case pending    = "Pending"
    case approved   = "Approved"
    case rejected   = "Rejected"
    case inTransit  = "In Transit"
    case completed  = "Completed"

    var color: Color {
        switch self {
        case .pending:   return RSMSTheme.warning
        case .approved:  return RSMSTheme.info
        case .rejected:  return RSMSTheme.danger
        case .inTransit: return Color(red: 43/255, green: 115/255, blue: 138/255)
        case .completed: return RSMSTheme.success
        }
    }

    var icon: String {
        switch self {
        case .pending:   return "clock.fill"
        case .approved:  return "checkmark.circle"
        case .rejected:  return "xmark.circle.fill"
        case .inTransit: return "shippingbox.and.arrow.backward.fill"
        case .completed: return "checkmark.seal.fill"
        }
    }

    static func from(_ movementStatus: MovementStatus) -> VendorReturnStatus {
        switch movementStatus {
        case .requested:  return .pending
        case .approved:   return .approved
        case .inTransit:  return .inTransit
        case .received, .completed: return .completed
        case .cancelled, .exception: return .rejected
        case .partial:    return .inTransit
        }
    }
}

// MARK: - Vendor Names (Mock)

struct VendorInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let contact: String
    let email: String
}

// MARK: - ViewModel

@Observable
final class VendorReturnViewModel {

    // MARK: - Data
    var movements: [InventoryMovement] = []
    var stores: [Store] = []
    var products: [Product] = []
    var stockItems: [StockItem] = []
    var isLoading = false
    var isUpdatingStatus = false
    var errorMessage: String?

    // MARK: - Mock Vendors
    let vendors: [VendorInfo] = [
        VendorInfo(name: "Maison Lumière Supplies", contact: "+33 1 42 68 53 00", email: "supply@maisonlumiere.fr"),
        VendorInfo(name: "Atelier Bijoux Paris", contact: "+33 1 44 51 22 10", email: "orders@atelierbijoux.com"),
        VendorInfo(name: "Geneva Watch Co.", contact: "+41 22 310 17 40", email: "returns@genevawatchco.ch"),
        VendorInfo(name: "Milano Leather House", contact: "+39 02 7200 1234", email: "logistics@milanoleather.it"),
        VendorInfo(name: "Kyoto Silk Artisans", contact: "+81 75 344 8900", email: "trade@kyotosilk.jp"),
        VendorInfo(name: "Royal Gem Traders", contact: "+44 20 7946 0958", email: "vendor@royalgem.co.uk"),
    ]

    // MARK: - Create Form State
    var showCreateSheet = false
    var returnId: String = ""
    var selectedVendor: VendorInfo?
    var purchaseOrderNumber: String = ""
    var selectedProduct: Product?
    var quantity: Int = 1
    var selectedReason: ReturnReason = .defective
    var priority: ReturnPriority = .medium
    var returnCart: [ReturnItem] = []
    var expectedPickupDate: Date = Calendar.current.date(byAdding: .day, value: 5, to: .now)!
    var returnNotes: String = ""
    var returnMethod: String = "Vendor Pickup"
    var isSubmitting = false
    var showSuccess = false

    // MARK: - Product Search
    var productSearchText = ""
    var searchResults: [Product] {
        guard !productSearchText.isEmpty else { return [] }
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(productSearchText) ||
            $0.sku.localizedCaseInsensitiveContains(productSearchText)
        }.prefix(8).map { $0 }
    }

    // MARK: - KPIs

    private var vendorReturns: [InventoryMovement] {
        movements.filter { $0.type == .vendorReturn }
    }

    var pendingCount: Int {
        vendorReturns.filter { $0.status == .requested }.count
    }

    var approvedCount: Int {
        vendorReturns.filter { $0.status == .approved }.count
    }

    var rejectedCount: Int {
        vendorReturns.filter { $0.status == .cancelled || $0.status == .exception }.count
    }

    var completedCount: Int {
        vendorReturns.filter { $0.status == .completed || $0.status == .received }.count
    }

    var inTransitCount: Int {
        vendorReturns.filter { $0.status == .inTransit }.count
    }

    var todayReturns: Int {
        let cal = Calendar.current
        return vendorReturns.filter { m in
            guard let date = m.requestedAt else { return false }
            return cal.isDateInToday(date)
        }.count
    }

    var totalReturnValue: Double {
        // Simplified: sum items * average product price
        Double(vendorReturns.reduce(0) { $0 + ($1.itemsExpected ?? 0) }) * 125.0
    }

    // MARK: - Sorted Returns for Feed
    var recentReturns: [InventoryMovement] {
        vendorReturns.sorted { (a, b) in
            (a.requestedAt ?? .distantPast) > (b.requestedAt ?? .distantPast)
        }
    }

    // MARK: - Available Stock for Selected Product
    var availableStock: Int {
        guard let product = selectedProduct else { return 0 }
        return stockForProduct(product)
    }

    func stockForProduct(_ product: Product) -> Int {
        return stockItems
            .filter { $0.productId == product.id && $0.status == .available }
            .reduce(0) { $0 + $1.quantity }
    }

    // MARK: - Load

    func load(dataStore: DataStore, storeId: UUID?) async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchStores()
            try await dataStore.fetchProducts()
            try await dataStore.fetchStockItems()
            try await dataStore.fetchInventoryMovements(type: .vendorReturn)

            stores = dataStore.stores
            products = dataStore.products
            stockItems = dataStore.stockItems
            movements = dataStore.inventoryMovements
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Generate Return ID

    func generateReturnID() {
        let digits = String(format: "%04d", Int.random(in: 1000...9999))
        returnId = "VR-\(digits)"
    }

    // MARK: - Reset Form

    func resetForm() {
        generateReturnID()
        selectedVendor = nil
        purchaseOrderNumber = ""
        selectedProduct = nil
        quantity = 1
        selectedReason = .defective
        priority = .medium
        returnCart = []
        expectedPickupDate = Calendar.current.date(byAdding: .day, value: 5, to: .now)!
        returnNotes = ""
        returnMethod = "Vendor Pickup"
        productSearchText = ""
    }

    // MARK: - Submit Return

    func submitReturn(dataStore: DataStore, requestedBy: UUID?, storeId: UUID?) async {
        guard let vendor = selectedVendor, !returnCart.isEmpty else { return }

        isSubmitting = true
        let priorityTag = "[\(priority.rawValue.uppercased())]"
        let reasonSummary = returnCart.map { "\($0.product.name) (\($0.reason.rawValue))" }.joined(separator: ", ")
        let notes = [priorityTag, returnId, "Vendor: \(vendor.name)", "Method: \(returnMethod)", returnNotes]
            .filter { !$0.isEmpty }
            .joined(separator: " — ")

        let totalItems = returnCart.reduce(0) { $0 + $1.quantity }
        let uniqueProducts = returnCart.count
        let reasonTitle = uniqueProducts == 1
            ? "Vendor Return — \(returnCart[0].product.name) (\(returnCart[0].reason.rawValue))"
            : "Vendor Return — \(uniqueProducts) products"

        let movement = InventoryMovement(
            id: UUID(),
            type: .vendorReturn,
            sourceId: storeId?.uuidString ?? "store",
            destinationId: vendor.name,
            status: .approved,
            requestedBy: requestedBy,
            approvedBy: requestedBy,
            requestedAt: .now,
            shippedAt: nil,
            receivedAt: nil,
            asnNumber: purchaseOrderNumber.isEmpty ? nil : purchaseOrderNumber,
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

    // MARK: - Update Status

    func updateStatus(for movementId: UUID, to newStatus: MovementStatus, dataStore: DataStore, user: UserProfile? = nil, storeId: UUID? = nil) async {
        isUpdatingStatus = true
        guard let index = movements.firstIndex(where: { $0.id == movementId }) else { 
            isUpdatingStatus = false
            return 
        }
        
        let current = movements[index]
        let updatedMovement = InventoryMovement(
            id: current.id,
            type: current.type,
            sourceId: current.sourceId,
            destinationId: current.destinationId,
            status: newStatus,
            requestedBy: current.requestedBy,
            approvedBy: current.approvedBy,
            requestedAt: current.requestedAt,
            shippedAt: newStatus == .inTransit ? .now : current.shippedAt,
            receivedAt: (newStatus == .completed || newStatus == .received) ? .now : current.receivedAt,
            asnNumber: current.asnNumber,
            itemsExpected: current.itemsExpected,
            itemsReceived: current.itemsReceived,
            reason: current.reason,
            notes: current.notes
        )
        
        do {
            try await dataStore.updateInventoryMovement(updatedMovement)
            withAnimation(.spring()) {
                movements[index] = updatedMovement
            }
            
            if let store = storeId {
                let uid = user?.id ?? UUID()
                let details = "Updated return status to \(newStatus.rawValue)."
                dataStore.logAudit(storeId: store, action: "Return Updated", entityType: "InventoryMovement", entityId: movementId, performedBy: uid, details: details)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isUpdatingStatus = false
    }

    // MARK: - Vendor Name from Movement

    func vendorName(for movement: InventoryMovement) -> String {
        let dest = movement.destinationId
        // If it matches a known vendor name, use it
        if vendors.contains(where: { $0.name == dest }) { return dest }
        // Otherwise try shortening
        if dest.count > 20 { return String(dest.prefix(18)) + "…" }
        return dest
    }

    func returnReason(for movement: InventoryMovement) -> String {
        guard let reason = movement.reason else { return "—" }
        // Strip the "Vendor Return — " prefix
        if reason.hasPrefix("Vendor Return — ") {
            return String(reason.dropFirst("Vendor Return — ".count))
        }
        return reason
    }
}

// MARK: - Mock State for Detail View
extension VendorReturnViewModel {
    var selectedLineItems: [ReturnItem] {
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
    
    func loadReturnDetail(movement: InventoryMovement, dataStore: DataStore) async {
        // No-op for now
    }
    
    func reportException(dataStore: DataStore, user: UserProfile, storeId: UUID) async {
        // No-op for now
    }
}
