//
//  DataStore.swift
//  RSMS
//
//  Central data repository handling Supabase queries and local caching.
//  Currently uses preview/mock data until the backend is fully wired.
//

import SwiftUI

@Observable
final class DataStore {
    var products: [Product] = []
    var stockItems: [StockItem] = []
    var auditTrails: [AuditTrail] = []
    var inventoryVariances: [InventoryVariance] = []
    
    // MARK: - Fetchers (Mocks for now)
    
    @MainActor
    func fetchProducts() async throws {
        // Simulate network delay
        try await Task.sleep(for: .seconds(0.5))
        self.products = Product.all
    }
    
    @MainActor
    func fetchStockItems(storeId: UUID) async throws {
        try await Task.sleep(for: .seconds(0.5))
        // Mock data usually ignores storeId for previews
        self.stockItems = [StockItem.preview]
    }
    
    @MainActor
    func fetchAuditTrails(storeId: UUID) async throws {
        try await Task.sleep(for: .seconds(0.5))
        self.auditTrails = [AuditTrail.preview]
    }
    
    @MainActor
    func fetchInventoryVariances(storeId: UUID) async throws {
        try await Task.sleep(for: .seconds(0.5))
        self.inventoryVariances = [InventoryVariance.preview]
    }
    
    // MARK: - Mutations (Mocks for now)
    
    @MainActor
    func updateStockItem(_ item: StockItem) async throws {
        try await Task.sleep(for: .seconds(0.3))
        if let idx = stockItems.firstIndex(where: { $0.id == item.id }) {
            stockItems[idx] = item
        } else {
            stockItems.append(item)
        }
    }
    
    func logAudit(storeId: UUID, action: String, entityType: String, entityId: UUID, performedBy: UUID, details: String) {
        // Fire and forget mock log
        let trail = AuditTrail(
            id: UUID(),
            storeId: storeId,
            action: action,
            entityType: entityType,
            entityId: entityId,
            performedBy: performedBy,
            timestamp: .now,
            details: details
        )
        Task { @MainActor in
            self.auditTrails.insert(trail, at: 0)
        }
    }
}
