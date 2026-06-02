//
//  PlanogramViewModel.swift
//  RSMS
//

import Foundation
import Observation
import CoreGraphics

@Observable
@MainActor
final class PlanogramViewModel {
    var zones: [MerchandisingZone] = []
    
    var availableInventory: [StoreProduct] = []
    
    var selectedZone: MerchandisingZone?
    var isLoading = false
    
    init() {
        self.selectedZone = nil
    }
    
    func load(dataStore: DataStore, storeId: UUID) async {
        guard availableInventory.isEmpty else { return } // Prevent double load
        isLoading = true
        defer { isLoading = false }
        
        do {
            if dataStore.products.isEmpty {
                try await dataStore.fetchProducts()
            }
            // If dataStore doesn't already have stock, fetch it.
            // But we'll ignore failure just in case `stock_items` isn't ready.
            try? await dataStore.fetchStockItems(storeId: storeId)
            
            // Map products to StoreProduct
            var mappedProducts: [StoreProduct] = []
            for product in dataStore.products {
                let stockForProduct = dataStore.stockItems.filter { $0.productId == product.id }
                let totalStock = stockForProduct.isEmpty ? 5 : stockForProduct.reduce(0) { $0 + $1.quantity }
                mappedProducts.append(StoreProduct(product: product, stockCount: totalStock))
            }
            
            self.availableInventory = mappedProducts
            
            // Fetch layout map / zones dynamically from Supabase
            let fetchedZones = try await PlanogramService.shared.fetchZones(for: storeId)
            self.zones = fetchedZones
            
            // Restore placed items from the planogram
            let planograms = try await PlanogramService.shared.fetchPlanograms(storeId: storeId)
            if let mainPlanogram = planograms.first {
                let items = try await PlanogramService.shared.fetchItems(for: mainPlanogram.id)
                for item in items {
                    if let zoneIndex = self.zones.firstIndex(where: { $0.id == item.shelfZoneId }),
                       let productIndex = self.availableInventory.firstIndex(where: { $0.id == item.productId }) {
                        let product = self.availableInventory[productIndex]
                        self.zones[zoneIndex].items.append(product)
                        self.availableInventory.remove(at: productIndex)
                    }
                }
            }
            
        } catch {
            print("Failed to load planogram data: \(error)")
        }
    }
    
    func saveLayout(storeId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let api = PlanogramService.shared
        
        // 1. Ensure we have a planogram for this store
        let planograms = try await api.fetchPlanograms(storeId: storeId)
        let mainPlanogram: Planogram
        if let first = planograms.first {
            mainPlanogram = first
        } else {
            let newPlanogram = Planogram(
                id: UUID(), storeId: storeId, name: "Main Floorplan", section: "Main",
                imageUrl: nil, isCompliant: true, lastCheckedAt: Date(),
                createdAt: Date(), updatedAt: Date(), campaignId: nil
            )
            mainPlanogram = try await api.createPlanogram(newPlanogram)
        }
        
        // 2. Clear old items for this planogram
        try await api.deleteItems(for: mainPlanogram.id)
        
        // 3. Save all new items placed in the zones
        for zone in zones {
            // Distribute items evenly along the x-axis within the zone
            let spacing = zone.width / Double(max(zone.items.count, 1))
            for (index, product) in zone.items.enumerated() {
                let item = PlanogramItem(
                    id: UUID(),
                    planogramId: mainPlanogram.id,
                    productId: product.id,
                    xPosition: zone.xPosition + (spacing * Double(index)),
                    yPosition: zone.yPosition,
                    width: 40,
                    height: 40,
                    shelfZoneId: zone.id,
                    skuLimit: 5,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                _ = try await api.saveItem(item)
            }
        }
    }
    
    func saveZonesLayout(storeId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let api = PlanogramService.shared
        let existingZones = try await api.fetchZones(for: storeId)
        
        let existingIds = Set(existingZones.map { $0.id })
        let currentIds = Set(zones.map { $0.id })
        
        let toDelete = existingIds.subtracting(currentIds)
        
        for id in toDelete {
            try? await api.deleteZone(id: id)
        }
        
        for zone in zones {
            if existingIds.contains(zone.id) {
                _ = try? await api.updateZone(zone)
            } else {
                _ = try? await api.createZone(zone)
            }
        }
    }
    
    func selectZone(_ zone: MerchandisingZone) {
        selectedZone = zone
    }
    
    func addProduct(_ product: StoreProduct, to zoneId: UUID) {
        guard let zoneIndex = zones.firstIndex(where: { $0.id == zoneId }) else { return }
        
        // Remove from inventory
        availableInventory.removeAll { $0.id == product.id }
        
        // Add to zone
        var updatedZone = zones[zoneIndex]
        updatedZone.items.append(product)
        zones[zoneIndex] = updatedZone
        
        // Update selected zone if it matches
        if selectedZone?.id == zoneId {
            selectedZone = updatedZone
        }
    }
    
    func removeProduct(_ product: StoreProduct, from zoneId: UUID) {
        guard let zoneIndex = zones.firstIndex(where: { $0.id == zoneId }) else { return }
        
        var updatedZone = zones[zoneIndex]
        updatedZone.items.removeAll { $0.id == product.id }
        zones[zoneIndex] = updatedZone
        
        // Add back to inventory
        availableInventory.append(product)
        
        if selectedZone?.id == zoneId {
            selectedZone = updatedZone
        }
    }
    
    func swapProduct(oldProduct: StoreProduct, newProduct: StoreProduct, in zoneId: UUID) {
        removeProduct(oldProduct, from: zoneId)
        addProduct(newProduct, to: zoneId)
    }
    
    func swapProductsInZone(_ product1Id: UUID, _ product2Id: UUID, in zoneId: UUID) {
        guard let zoneIndex = zones.firstIndex(where: { $0.id == zoneId }) else { return }
        var updatedZone = zones[zoneIndex]
        guard let idx1 = updatedZone.items.firstIndex(where: { $0.id == product1Id }),
              let idx2 = updatedZone.items.firstIndex(where: { $0.id == product2Id }) else { return }
        
        updatedZone.items.swapAt(idx1, idx2)
        zones[zoneIndex] = updatedZone
        
        if selectedZone?.id == zoneId {
            selectedZone = updatedZone
        }
    }
}
