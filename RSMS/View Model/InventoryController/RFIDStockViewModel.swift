//
//  RFIDStockViewModel.swift
//  RSMS
//
//  ViewModel for the RFID Stock Management screen.
//  CRUD for stock items, RFID scans, variances, and shrinkage.
//

import SwiftUI

@Observable
final class RFIDStockViewModel {

    private let dataStore: DataStore
    private let storeId: UUID
    private let userId: UUID

    var searchQuery = ""
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
            try await dataStore.fetchUsers(storeId: storeId)
            try await dataStore.fetchStockItems(storeId: storeId)
            try await dataStore.fetchRFIDScanRecords(storeId: storeId)
            try await dataStore.fetchInventoryVariances(storeId: storeId)
            try await dataStore.fetchShrinkageAnalytics(storeId: storeId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Stock
    var allStock: [StockItem] { dataStore.stockItems.filter { $0.storeId == storeId } }

    var filteredStock: [StockItem] {
        guard !searchQuery.isEmpty else { return allStock }
        let q = searchQuery.lowercased()
        return allStock.filter {
            dataStore.productName(for: $0.productId).lowercased().contains(q) ||
            (dataStore.product(by: $0.productId)?.sku.lowercased().contains(q) ?? false) ||
            ($0.rfidTag?.lowercased().contains(q) ?? false)
        }
    }

    func updateStockLocation(_ item: StockItem) async throws {
        try await dataStore.updateStockItem(item)
    }

    // MARK: - RFID Scans
    var rfidScanRecords: [RFIDScanRecord] {
        dataStore.rfidScanRecords.filter { $0.storeId == storeId }.sorted { $0.scannedAt > $1.scannedAt }
    }

    func createScanRecord(itemsScanned: Int, exceptions: Int, notes: String?) async throws {
        let record = RFIDScanRecord(
            id: UUID(), storeId: storeId, scannedBy: userId,
            scannedAt: .now, itemsScanned: itemsScanned,
            exceptionsFound: exceptions, notes: notes
        )
        try await dataStore.createRFIDScanRecord(record)
        dataStore.logAudit(storeId: storeId, action: "RFID Scan Completed", entityType: "RFIDScanRecord", entityId: record.id, performedBy: userId, details: "\(itemsScanned) items scanned, \(exceptions) exceptions")
    }

    // MARK: - Variances
    var variances: [InventoryVariance] { dataStore.inventoryVariances.filter { $0.storeId == storeId } }
    var openVariances: [InventoryVariance] { variances.filter { $0.status == .open || $0.status == .investigating } }

    func reportVariance(productId: UUID, expected: Int, actual: Int) async throws {
        let v = InventoryVariance(
            id: UUID(), storeId: storeId, productId: productId,
            expectedQty: expected, actualQty: actual, variance: actual - expected,
            reportedBy: userId, status: .open, cycleCountId: nil,
            resolution: nil, reportedAt: .now, resolvedAt: nil
        )
        try await dataStore.createInventoryVariance(v)
        dataStore.logAudit(storeId: storeId, action: "Variance Reported", entityType: "InventoryVariance", entityId: v.id, performedBy: userId)
    }

    func resolveVariance(_ v: InventoryVariance, resolution: String) async throws {
        let resolved = InventoryVariance(
            id: v.id, storeId: v.storeId, productId: v.productId,
            expectedQty: v.expectedQty, actualQty: v.actualQty, variance: v.variance,
            reportedBy: v.reportedBy, status: .resolved, cycleCountId: v.cycleCountId,
            resolution: resolution, reportedAt: v.reportedAt, resolvedAt: .now
        )
        try await dataStore.updateInventoryVariance(resolved)
    }

    // MARK: - Shrinkage
    var shrinkageAnalytics: ShrinkageAnalytics? {
        dataStore.shrinkageAnalytics.first { $0.storeId == storeId }
    }

    // MARK: - Helpers
    func productName(for id: UUID) -> String { dataStore.productName(for: id) }
    func userName(for id: UUID) -> String { dataStore.userName(for: id) }

    func statusColor(_ status: StockStatus) -> Color {
        switch status {
        case .available: return RSMSTheme.success
        case .reserved:  return RSMSTheme.info
        case .sold:      return RSMSTheme.gold
        case .inTransit: return RSMSTheme.warning
        case .damaged:   return RSMSTheme.danger
        case .onLoan:    return RSMSTheme.textSecondary
        }
    }

    func varianceStatusColor(_ status: VarianceStatus) -> Color {
        switch status {
        case .open:          return RSMSTheme.danger
        case .investigating: return RSMSTheme.warning
        case .resolved:      return RSMSTheme.success
        case .writeOff:      return RSMSTheme.textSecondary
        }
    }
}
