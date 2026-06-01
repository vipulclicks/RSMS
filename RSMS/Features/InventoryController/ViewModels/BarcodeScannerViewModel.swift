//
//  BarcodeScannerViewModel.swift
//  RSMS
//
//  Manages all barcode scanning logic — product lookup, stock updates,
//  duplicate detection, audit logging, and session history.
//  Wired to Supabase via the shared DataStore.
//
//  ScanMode and ScanLogEntry live in InventoryModels.swift (domain types).
//  ScanMode.badgeColor is extended here as it references RSMSTheme (SwiftUI).
//

import SwiftUI

// MARK: - ScanMode UI Extension

/// Badge colour for the scan mode chip — kept here because RSMSTheme is SwiftUI.
extension ScanMode {
    var badgeColor: Color {
        switch self {
        case .stockIn:      return RSMSTheme.gold
        case .verification: return RSMSTheme.success
        case .audit:        return RSMSTheme.info
        }
    }
}

// MARK: - Scan State

enum ScanState: Equatable {
    case idle
    case loading
    case found(product: Product, stockItem: StockItem?)
    case notFound(barcode: String)
    case duplicate(product: Product)
    case error(message: String)

    /// True when the result sheet should be presented.
    var isResultState: Bool {
        switch self {
        case .found, .notFound, .duplicate, .error: return true
        case .idle, .loading:                        return false
        }
    }
}

// MARK: - ViewModel

@Observable
final class BarcodeScannerViewModel {

    var scanMode: ScanMode = .stockIn
    var state: ScanState = .idle
    var sessionLog: [ScanLogEntry] = []
    var isConfirming: Bool = false

    /// SKUs confirmed in this session — used for duplicate prevention.
    private var confirmedSKUs: Set<String> = []

    // MARK: - Preload

    /// Pre-warms the DataStore cache before the first scan so lookups are instant.
    @MainActor
    func preload(dataStore: DataStore, storeId: UUID?) async {
        if dataStore.products.isEmpty {
            try? await dataStore.fetchProducts()
        }
        if let sid = storeId, dataStore.stockItems.isEmpty {
            try? await dataStore.fetchStockItems(storeId: sid)
        }
    }

    // MARK: - Process Barcode

    /// Looks up the barcode against DataStore products and transitions state accordingly.
    @MainActor
    func process(barcode: String, dataStore: DataStore, storeId: UUID?) async {
        let normalized = barcode.trimmingCharacters(in: .whitespaces)
        guard !normalized.isEmpty else { return }

        state = .loading

        // Load products if cache is empty
        if dataStore.products.isEmpty {
            try? await dataStore.fetchProducts()
        }

        // Load stock items if cache is empty
        if let sid = storeId, dataStore.stockItems.isEmpty {
            try? await dataStore.fetchStockItems(storeId: sid)
        }

        // Exact SKU match first, then partial
        let product = dataStore.products.first {
            $0.sku.caseInsensitiveCompare(normalized) == .orderedSame
        } ?? dataStore.products.first {
            $0.sku.localizedCaseInsensitiveContains(normalized)
        }

        guard let product else {
            state = .notFound(barcode: normalized)
            return
        }

        // Duplicate detection — only after confirmed SKUs
        if confirmedSKUs.contains(product.sku.uppercased()) {
            state = .duplicate(product: product)
            return
        }

        // Find matching stock item for this product at this store
        let stockItem = dataStore.stockItems.first {
            $0.productId == product.id && $0.storeId == storeId
        }

        state = .found(product: product, stockItem: stockItem)
    }

    // MARK: Confirm (Write to Supabase)

    /// Applies the scan to Supabase: updates stock (Stock In mode) and writes an audit trail entry.
    @MainActor
    func confirm(product: Product, stockItem: StockItem?, enteredCount: Int? = nil, dataStore: DataStore, user: UserProfile) async {
        isConfirming = true
        defer { isConfirming = false }

        do {
            // Update stock quantity only in Stock In mode
            if scanMode == .stockIn, let existing = stockItem {
                let updated = StockItem(
                    id: existing.id,
                    productId: existing.productId,
                    storeId: existing.storeId,
                    quantity: existing.quantity + 1,
                    rfidTag: existing.rfidTag,
                    location: existing.location,
                    status: existing.status,
                    lastScannedAt: .now,
                    updatedAt: .now
                )
                try await dataStore.updateStockItem(updated)
            } else if scanMode == .verification, let existing = stockItem {
                let updated = StockItem(
                    id: existing.id,
                    productId: existing.productId,
                    storeId: existing.storeId,
                    quantity: existing.quantity, // don't change qty — just record the check
                    rfidTag: existing.rfidTag,
                    location: existing.location,
                    status: existing.status,
                    lastScannedAt: .now,
                    updatedAt: .now
                )
                try await dataStore.updateStockItem(updated)

                if let actualQty = enteredCount, actualQty != existing.quantity, let storeId = user.storeId {
                    let variance = InventoryVariance(
                        id: UUID(),
                        storeId: storeId,
                        productId: product.id,
                        expectedQty: existing.quantity,
                        actualQty: actualQty,
                        variance: actualQty - existing.quantity,
                        reportedBy: user.id,
                        status: .open,
                        cycleCountId: nil,
                        resolution: nil,
                        reportedAt: .now,
                        resolvedAt: nil
                    )
                    try await dataStore.createInventoryVariance(variance)
                }
            }

            // Fire-and-forget audit log
            if let storeId = user.storeId {
                dataStore.logAudit(
                    storeId: storeId,
                    action: scanMode.auditAction,
                    entityType: "Product",
                    entityId: product.id,
                    performedBy: user.id,
                    details: "SKU: \(product.sku) · \(product.name)"
                )
            }

            // Record in session and mark SKU as confirmed
            confirmedSKUs.insert(product.sku.uppercased())
            sessionLog.insert(
                ScanLogEntry(
                    id: UUID(),
                    sku: product.sku,
                    productName: product.name,
                    timestamp: .now,
                    mode: scanMode,
                    success: true
                ),
                at: 0
            )

            // Dismiss the result sheet
            state = .idle

        } catch {
            state = .error(message: error.localizedDescription)
        }
    }

    // MARK: Force-Add Duplicate

    /// Bypasses duplicate guard for a product already scanned this session.
    @MainActor
    func forceConfirm(product: Product, stockItem: StockItem?, enteredCount: Int? = nil, dataStore: DataStore, user: UserProfile) async {
        confirmedSKUs.remove(product.sku.uppercased())
        state = .found(product: product, stockItem: stockItem)
        await confirm(product: product, stockItem: stockItem, enteredCount: enteredCount, dataStore: dataStore, user: user)
    }

    // MARK: Session Management

    func resetState() {
        state = .idle
    }

    func clearSession() {
        confirmedSKUs = []
        sessionLog = []
        state = .idle
    }
}
