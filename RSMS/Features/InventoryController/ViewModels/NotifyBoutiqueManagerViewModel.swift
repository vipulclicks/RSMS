//
//  NotifyBoutiqueManagerViewModel.swift
//  RSMS
//
//  ViewModel for the "Notify Boutique Manager" screen.
//  Manages low stock alerts and notification state.
//

import SwiftUI
import Observation

// MARK: - Low Stock Alert Model

struct LowStockAlertItem: Identifiable, Hashable {
    let id: UUID
    let product: Product
    let currentQty: Int
    let thresholdQty: Int
    let lastUpdated: Date
    var isManagerNotified: Bool
    
    // Derived properties for UI
    var progress: Double {
        guard thresholdQty > 0 else { return 0 }
        return Double(currentQty) / Double(thresholdQty)
    }
    
    var statusText: String {
        if currentQty == 0 { return "OUT OF STOCK" }
        return "CRITICAL"
    }
    
    var statusColor: Color {
        if currentQty == 0 { return RSMSTheme.textPrimary }
        return RSMSTheme.textPrimary.opacity(0.8)
    }
}

// MARK: - ViewModel

@Observable
final class NotifyBoutiqueManagerViewModel {
    
    // MARK: - State
    
    var lowStockItems: [LowStockAlertItem] = []
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Computed Properties for Summary Cards
    
    var lowStockCount: Int {
        lowStockItems.count
    }
    
    var criticalCount: Int {
        lowStockItems.filter { $0.currentQty <= ($0.thresholdQty / 2) }.count
    }
    
    var notifiedCount: Int {
        lowStockItems.filter { $0.isManagerNotified }.count
    }
    
    var activeRequestsCount: Int {
        // Items that are notified are considered active requests for replenishment.
        notifiedCount
    }
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Actions
    
    func notifyManager(for itemID: UUID) {
        if let index = lowStockItems.firstIndex(where: { $0.id == itemID }) {
            lowStockItems[index].isManagerNotified = true
        }
    }
    
    func load(dataStore: DataStore, storeId: UUID?) async {
        guard let storeId = storeId else { return }
        
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchProducts()
            try await dataStore.fetchStockItems()
            
            // Filter stock items for the current store
            let storeStock = dataStore.stockItems.filter { $0.storeId == storeId && $0.status == .available }
            
            // Group by product
            var qtyByProduct: [UUID: Int] = [:]
            for item in storeStock {
                qtyByProduct[item.productId, default: 0] += item.quantity
            }
            
            var alerts: [LowStockAlertItem] = []
            
            // Check all products for this store (assuming if it's not in stockItems, quantity is 0, but we only have what is returned. Wait, a store might have 0 of a product so it might not even appear in stockItems. For simplicity, we check products that have some stock or previously had stock.)
            for product in dataStore.products {
                let qty = qtyByProduct[product.id] ?? 0
                let threshold = 3 // Hardcoded threshold since it's not in the database schema yet
                
                if qty <= threshold {
                    alerts.append(
                        LowStockAlertItem(
                            id: product.id,
                            product: product,
                            currentQty: qty,
                            thresholdQty: threshold,
                            lastUpdated: .now,
                            isManagerNotified: false
                        )
                    )
                }
            }
            
            // Sort by lowest quantity first
            self.lowStockItems = alerts.sorted { $0.currentQty < $1.currentQty }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
