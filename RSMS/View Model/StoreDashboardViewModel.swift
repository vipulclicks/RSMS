//
//  StoreDashboardViewModel.swift
//  RSMS
//
//  Created by Nitin Singh on 21/05/26.
//

import SwiftUI
import Observation

// MARK: - Alert Data Model
struct LowStockAlert: Identifiable {
    let id = UUID()
    let product: Product
    let stockItem: StockItem
}

// MARK: - Dashboard View Model
@Observable
class StoreDashboardViewModel {
    // 1. Data Store
    var products: [Product] = Product.all
    
    // We start with 1 item naturally low (Watch = 1 qty) and 1 item fine (Ring = 5 qty)
    var stockItems: [StockItem] = [
        StockItem.preview, // The watch (Qty: 1)
        StockItem(id: UUID(), productId: Product.previewRing.id, storeId: Store.preview.id, quantity: 5, rfidTag: "RFID-002", location: "Display A", status: .available, lastScannedAt: .now, updatedAt: .now)
    ]
    
    let lowStockThreshold: Int = 2
    
    // 2. Dynamic Alert Calculation
    /// Automatically calculates and returns alerts for items below the threshold.
    var lowStockAlerts: [LowStockAlert] {
        stockItems
            .filter { $0.quantity <= lowStockThreshold }
            .compactMap { stockItem in
                guard let product = products.first(where: { $0.id == stockItem.productId }) else { return nil }
                return LowStockAlert(product: product, stockItem: stockItem)
            }
    }
    
    // 3. Testing Helper
    /// Use this to test the "updates automatically" acceptance criteria in the UI
    func simulateStockDrop() {
        // Find the ring and reduce its stock to 1 to trigger a new live alert
        if let index = stockItems.firstIndex(where: { $0.productId == Product.previewRing.id }) {
            var modified = stockItems[index]
            let newQty = max(0, modified.quantity - 4) // Drops from 5 to 1
            
            modified = StockItem(id: modified.id, productId: modified.productId, storeId: modified.storeId, quantity: newQty, rfidTag: modified.rfidTag, location: modified.location, status: modified.status, lastScannedAt: modified.lastScannedAt, updatedAt: .now)
            
            withAnimation(.spring) {
                stockItems[index] = modified
            }
        }
    }
    func reorderItem(for productId: UUID) {
            if let index = stockItems.firstIndex(where: { $0.productId == productId }) {
                var modified = stockItems[index]
                // Add 10 to the quantity so it is no longer "Low Stock"
                let newQty = modified.quantity + 10
                
                modified = StockItem(id: modified.id, productId: modified.productId, storeId: modified.storeId, quantity: newQty, rfidTag: modified.rfidTag, location: modified.location, status: modified.status, lastScannedAt: modified.lastScannedAt, updatedAt: .now)
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    stockItems[index] = modified
                }
            }
        }
}
