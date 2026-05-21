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
        // Mock logic: some subset of items are awaiting refill. 
        // For realism, let's say items that are notified are active requests.
        notifiedCount
    }
    
    // MARK: - Initialization
    
    init() {
        loadMockData()
    }
    
    // MARK: - Actions
    
    func notifyManager(for itemID: UUID) {
        if let index = lowStockItems.firstIndex(where: { $0.id == itemID }) {
            lowStockItems[index].isManagerNotified = true
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func loadMockData() {
        // Generating some realistic mock data based on the prompt's requested categories
        // Handbags, Watches, Heels, Dresses
        
        let bag = Product(
            id: UUID(), sku: "LTH-BAG-CL-001", name: "Vendôme Clutch", category: "Handbags", subcategory: "Evening",
            brand: "Maison Lumière", collection: "Vendôme", material: "Calfskin", price: 3200, currency: "EUR",
            imageURL: nil, description: "", isActive: true, createdAt: .now, updatedAt: .now
        )
        
        let watch = Product(
            id: UUID(), sku: "WCH-AUT-RG-001", name: "Lumière Grande Complication", category: "Watches", subcategory: "Automatic",
            brand: "Maison Lumière", collection: "Heritage", material: "Rose Gold", price: 38000, currency: "EUR",
            imageURL: nil, description: "", isActive: true, createdAt: .now, updatedAt: .now
        )
        
        let heel = Product(
            id: UUID(), sku: "SHS-HL-BK-001", name: "Parisienne Stiletto", category: "Heels", subcategory: "Pumps",
            brand: "Maison Lumière", collection: "Classics", material: "Patent Leather", price: 950, currency: "EUR",
            imageURL: nil, description: "", isActive: true, createdAt: .now, updatedAt: .now
        )
        
        let dress = Product(
            id: UUID(), sku: "RTW-DRS-SL-001", name: "Midnight Silk Gown", category: "Dresses", subcategory: "Evening Wear",
            brand: "Maison Lumière", collection: "Gala", material: "100% Silk", price: 4500, currency: "EUR",
            imageURL: nil, description: "", isActive: true, createdAt: .now, updatedAt: .now
        )
        
        lowStockItems = [
            LowStockAlertItem(id: bag.id, product: bag, currentQty: 1, thresholdQty: 5, lastUpdated: Calendar.current.date(byAdding: .minute, value: -12, to: .now)!, isManagerNotified: false),
            LowStockAlertItem(id: watch.id, product: watch, currentQty: 0, thresholdQty: 2, lastUpdated: Calendar.current.date(byAdding: .hour, value: -1, to: .now)!, isManagerNotified: false),
            LowStockAlertItem(id: heel.id, product: heel, currentQty: 2, thresholdQty: 8, lastUpdated: Calendar.current.date(byAdding: .minute, value: -45, to: .now)!, isManagerNotified: true),
            LowStockAlertItem(id: dress.id, product: dress, currentQty: 1, thresholdQty: 4, lastUpdated: Calendar.current.date(byAdding: .hour, value: -3, to: .now)!, isManagerNotified: false)
        ]
    }
}
