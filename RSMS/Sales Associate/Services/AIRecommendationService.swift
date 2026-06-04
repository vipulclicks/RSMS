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
        
        // Helper to pick next distinct product matching a condition
        func pickDistinct(where predicate: (Product) -> Bool) -> Product? {
            for product in shuffledProducts {
                if predicate(product) && !selected.contains(where: { $0.id == product.id }) {
                    return product
                }
            }
            return nil
        }
        
        // Helper to pick any distinct product as fallback
        func pickAnyDistinct() -> Product? {
            return pickDistinct(where: { _ in true })
        }
        
        // A naive categorization based on common luxury strings
        // In reality, this would use `product.subcategory` and a recommendation ML model
        
        if let main = pickDistinct(where: { $0.category.localizedCaseInsensitiveContains("Ready to Wear") || $0.category.localizedCaseInsensitiveContains("Apparel") }) {
            selected.append(main)
        } else if let fallback = pickAnyDistinct() {
            selected.append(fallback)
        }
        
        if let shoe = pickDistinct(where: { $0.category.localizedCaseInsensitiveContains("Shoes") || $0.category.localizedCaseInsensitiveContains("Footwear") }) {
            selected.append(shoe)
        } else if let fallback = pickAnyDistinct() {
            selected.append(fallback)
        }
        
        if let bag = pickDistinct(where: { $0.category.localizedCaseInsensitiveContains("Bags") || $0.category.localizedCaseInsensitiveContains("Leather") }) {
            selected.append(bag)
        } else if let fallback = pickAnyDistinct() {
            selected.append(fallback)
        }
        
        if let jewelry = pickDistinct(where: { $0.category.localizedCaseInsensitiveContains("Jewelry") || $0.category.localizedCaseInsensitiveContains("Watches") }) {
            selected.append(jewelry)
        } else if let fallback = pickAnyDistinct() {
            selected.append(fallback)
        }
        
        return selected
    }
}
