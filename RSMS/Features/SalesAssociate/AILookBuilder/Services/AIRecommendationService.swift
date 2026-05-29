//
//  AIRecommendationService.swift
//  RSMS
//

import Foundation
import SwiftData

class AIRecommendationService {
    
    /// Generates curated fashion looks based on client profile, occasion, and available inventory.
    func generateLooks(for client: ClientProfile, occasion: Occasion, dataStore: DataStore) async -> [GeneratedLook] {
        // Fetch all products that are active and theoretically in stock
        // For a real implementation, we would check `stockItems` mapping, 
        // but for now, we use `isActive` as a proxy for available products to build the look.
        let availableProducts = dataStore.products.filter { $0.isActive }
        
        guard !availableProducts.isEmpty else { return [] }
        
        var generatedLooks: [GeneratedLook] = []
        
        // Mock logic: we will generate 3 looks per occasion request
        let lookNames = getLookNames(for: occasion)
        
        for name in lookNames {
            let productsForLook = selectProducts(for: occasion, client: client, from: availableProducts)
            if !productsForLook.isEmpty {
                let look = GeneratedLook(
                    occasion: occasion,
                    products: productsForLook,
                    name: name
                )
                generatedLooks.append(look)
            }
        }
        
        return generatedLooks
    }
    
    private func getLookNames(for occasion: Occasion) -> [String] {
        switch occasion {
        case .wedding:
            return ["Classic Elegance", "Modern Romance", "Vanguard Nuptials"]
        case .formal:
            return ["Executive Presence", "Gala Ready", "Timeless Silhouette"]
        case .casual:
            return ["Weekend Chic", "Elevated Basics", "Urban Explorer"]
        case .party:
            return ["Midnight Glamour", "Statement Maker", "Bold & Brilliant"]
        }
    }
    
    private func selectProducts(for occasion: Occasion, client: ClientProfile, from products: [Product]) -> [Product] {
        // Here we simulate an AI picking a combination of items:
        // 1 Main Wear (e.g., Dress or Suit equivalent)
        // 1 Pair of Shoes
        // 1 Bag or Accessory
        // 1 Piece of Jewelry
        
        var selected: [Product] = []
        
        // To make it deterministic-ish for the UI mock, we shuffle the array based on occasion string
        let shuffledProducts = products.shuffled()
        
        // A naive categorization based on common luxury strings
        // In reality, this would use `product.subcategory` and a recommendation ML model
        
        let mainWear = shuffledProducts.first { $0.category.localizedCaseInsensitiveContains("Ready to Wear") || $0.category.localizedCaseInsensitiveContains("Apparel") }
        let shoes = shuffledProducts.first { $0.category.localizedCaseInsensitiveContains("Shoes") || $0.category.localizedCaseInsensitiveContains("Footwear") }
        let bag = shuffledProducts.first { $0.category.localizedCaseInsensitiveContains("Bags") || $0.category.localizedCaseInsensitiveContains("Leather") }
        let jewelry = shuffledProducts.first { $0.category.localizedCaseInsensitiveContains("Jewelry") || $0.category.localizedCaseInsensitiveContains("Watches") }
        
        // Fallback to random items if categories don't explicitly match (to ensure looks generate for preview)
        var fallbackIndex = 0
        
        if let main = mainWear { selected.append(main) } else { 
            if fallbackIndex < shuffledProducts.count { selected.append(shuffledProducts[fallbackIndex]); fallbackIndex += 1 }
        }
        
        if let shoe = shoes { selected.append(shoe) } else { 
            if fallbackIndex < shuffledProducts.count { selected.append(shuffledProducts[fallbackIndex]); fallbackIndex += 1 }
        }
        
        if let b = bag { selected.append(b) } else { 
            if fallbackIndex < shuffledProducts.count { selected.append(shuffledProducts[fallbackIndex]); fallbackIndex += 1 }
        }
        
        if let jewel = jewelry { selected.append(jewel) } else { 
            if fallbackIndex < shuffledProducts.count { selected.append(shuffledProducts[fallbackIndex]); fallbackIndex += 1 }
        }
        
        return selected
    }
}
