//
//  AILookBuilderViewModel.swift
//  RSMS
//

import Foundation
import Observation
import SwiftUI

@Observable
final class AILookBuilderViewModel {
    
    // Dependencies
    private let dataStore: DataStore
    private let recommendationService: AIRecommendationService
    let client: ClientProfile
    let associateId: UUID
    
    // State
    var selectedOccasion: Occasion = .wedding
    var generatedLooks: [GeneratedLook] = []
    var savedOutfits: [LookBuilderOutfit] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var savedLookIds: Set<UUID> = []
    
    init(client: ClientProfile, dataStore: DataStore, associateId: UUID, recommendationService: AIRecommendationService = AIRecommendationService()) {
        self.client = client
        self.dataStore = dataStore
        self.associateId = associateId
        self.recommendationService = recommendationService
    }
    
    @MainActor
    func generateLooks() async {
        isLoading = true
        errorMessage = nil
        
        // Add a slight delay to simulate "AI Thinking" for UX
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        let looks = await recommendationService.generateLooks(for: client, occasion: selectedOccasion, dataStore: dataStore)
        
        if looks.isEmpty {
            errorMessage = "No suitable products found for this occasion in the current inventory."
        } else {
            generatedLooks = looks
        }
        
        isLoading = false
    }
    
    @MainActor
    func fetchSavedLooks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await dataStore.fetchLookBuilderOutfits(associateId: associateId)
            savedOutfits = dataStore.lookBuilderOutfits.filter { $0.clientId == client.id }
            isLoading = false
        } catch {
            errorMessage = "Failed to load saved looks: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    @MainActor
    func saveLook(_ look: GeneratedLook) async {
        isLoading = true
        errorMessage = nil
        
        let outfit = LookBuilderOutfit(
            id: UUID(),
            associateId: associateId,
            clientId: client.id,
            name: look.name,
            productIds: look.products.map { $0.id },
            imageURL: nil,
            notes: "AI Generated Look for \(look.occasion.rawValue)",
            createdAt: Date()
        )
        
        do {
            try await dataStore.createLookBuilderOutfit(outfit)
            savedLookIds.insert(look.id)
            savedOutfits.append(outfit)
            isLoading = false
        } catch {
            errorMessage = "Failed to save the look: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    @MainActor
    func unsaveLook(_ look: GeneratedLook) async {
        let lookProductIds = Set(look.products.map { $0.id })
        guard let outfit = savedOutfits.first(where: { Set($0.productIds) == lookProductIds || $0.id == look.id }) else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await dataStore.deleteLookBuilderOutfit(id: outfit.id)
            savedLookIds.remove(look.id)
            savedOutfits.removeAll { $0.id == outfit.id }
            isLoading = false
        } catch {
            errorMessage = "Failed to unsave the look: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // Check if a generated look matches a saved look's products
    func isLookSaved(_ look: GeneratedLook) -> Bool {
        let lookProductIds = Set(look.products.map { $0.id })
        return savedOutfits.contains { Set($0.productIds) == lookProductIds }
    }
    
    // Map a saved outfit model to a generated look model for UI rendering
    func generatedLook(from outfit: LookBuilderOutfit) -> GeneratedLook {
        let products = outfit.productIds.compactMap { dataStore.product(by: $0) }
        
        var occasion: Occasion = .casual
        if let notes = outfit.notes {
            for occ in Occasion.allCases {
                if notes.localizedCaseInsensitiveContains(occ.rawValue) {
                    occasion = occ
                    break
                }
            }
        }
        
        return GeneratedLook(
            id: outfit.id,
            occasion: occasion,
            products: products,
            name: outfit.name
        )
    }
    
    // Helper to simulate sharing using standard SwiftUI share sheet payload
    func sharePayload(for look: GeneratedLook) -> String {
        var text = "Check out this \(look.name) curated for you!\n\n"
        for product in look.products {
            text += "- \(product.name) (₹\(Int(product.price).formatted()))\n"
        }
        text += "\nTotal: ₹\(Int(look.totalPrice).formatted())"
        return text
    }
}
