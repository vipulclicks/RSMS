//
//  AssistedSellingViewModel.swift
//  RSMS
//
//  ViewModel for the Assisted Selling & Product Catalog screen.
//  CRUD for products, AI recommendations, and look builder outfits.
//

import SwiftUI

@Observable
final class AssistedSellingViewModel {

    private let dataStore: DataStore
    private let associateId: UUID

    var searchQuery = ""
    var selectedCategory: String? = nil
    var isLoading = false
    var errorMessage: String?

    init(dataStore: DataStore, associateId: UUID) {
        self.dataStore   = dataStore
        self.associateId = associateId
    }

    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchProducts()
            try await dataStore.fetchLookBuilderOutfits(associateId: associateId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Products
    var allProducts: [Product] { dataStore.products.filter(\.isActive) }

    var filteredProducts: [Product] {
        var result = allProducts
        if let cat = selectedCategory { result = result.filter { $0.category == cat } }
        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(q) ||
                $0.sku.lowercased().contains(q) ||
                $0.brand.lowercased().contains(q)
            }
        }
        return result
    }

    var categories: [String] {
        Array(Set(allProducts.map(\.category))).sorted()
    }

    // MARK: - AI Recommendations
    func recommendations(for clientId: UUID) -> [AIRecommendation] {
        dataStore.aiRecommendations.filter { $0.clientId == clientId }
    }

    func loadRecommendations(for clientId: UUID) async throws {
        try await dataStore.fetchAIRecommendations(clientId: clientId)
    }

    func acceptRecommendation(_ rec: AIRecommendation) async throws {
        let updated = AIRecommendation(
            id: rec.id, clientId: rec.clientId, productId: rec.productId,
            type: rec.type, confidence: rec.confidence, reason: rec.reason,
            isAccepted: true, createdAt: rec.createdAt
        )
        try await dataStore.updateAIRecommendation(updated)
    }

    func dismissRecommendation(_ rec: AIRecommendation) async throws {
        let updated = AIRecommendation(
            id: rec.id, clientId: rec.clientId, productId: rec.productId,
            type: rec.type, confidence: rec.confidence, reason: rec.reason,
            isAccepted: false, createdAt: rec.createdAt
        )
        try await dataStore.updateAIRecommendation(updated)
    }

    // MARK: - Look Builder
    var outfits: [LookBuilderOutfit] { dataStore.lookBuilderOutfits.filter { $0.associateId == associateId } }

    func createOutfit(_ outfit: LookBuilderOutfit) async throws {
        try await dataStore.createLookBuilderOutfit(outfit)
    }

    func updateOutfit(_ outfit: LookBuilderOutfit) async throws {
        try await dataStore.updateLookBuilderOutfit(outfit)
    }

    func deleteOutfit(id: UUID) async throws {
        try await dataStore.deleteLookBuilderOutfit(id: id)
    }

    // MARK: - Helpers
    func productName(for id: UUID) -> String { dataStore.productName(for: id) }
    func product(by id: UUID) -> Product? { dataStore.product(by: id) }
}
