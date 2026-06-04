//
//  LookBuilderViewModel.swift
//  RSMS
//
//  ViewModel for the Look Builder screen.
//  Manages outfit list, editing, and product selection.
//

import SwiftUI

@Observable
final class LookBuilderViewModel {

    // MARK: - Data
    // TODO: Replace mock data with Supabase fetch
    private(set) var outfits: [LookBuilderOutfit] = []
    private(set) var products: [Product] = []
    private(set) var clients: [ClientProfile] = []

    // MARK: - Editor State
    var isShowingEditor = false
    var editingOutfit: LookBuilderOutfit?
    var outfitName = ""
    var outfitNotes = ""
    var selectedClientId: UUID?
    var selectedProductIds: Set<UUID> = []
    var searchQuery = ""

    // MARK: - Computed

    var filteredProducts: [Product] {
        guard !searchQuery.isEmpty else { return products }
        let q = searchQuery.lowercased()
        return products.filter {
            $0.name.lowercased().contains(q) ||
            $0.sku.lowercased().contains(q) ||
            $0.category.lowercased().contains(q)
        }
    }

    var selectedProducts: [Product] {
        products.filter { selectedProductIds.contains($0.id) }
    }

    var canSaveOutfit: Bool {
        !outfitName.trimmingCharacters(in: .whitespaces).isEmpty && !selectedProductIds.isEmpty
    }

    // MARK: - Actions

    func startNewOutfit() {
        editingOutfit = nil
        outfitName = ""
        outfitNotes = ""
        selectedClientId = nil
        selectedProductIds = []
        searchQuery = ""
        isShowingEditor = true
    }

    func startEditing(_ outfit: LookBuilderOutfit) {
        editingOutfit = outfit
        outfitName = outfit.name
        outfitNotes = outfit.notes ?? ""
        selectedClientId = outfit.clientId
        selectedProductIds = Set(outfit.productIds)
        searchQuery = ""
        isShowingEditor = true
    }

    func toggleProduct(_ productId: UUID) {
        if selectedProductIds.contains(productId) {
            selectedProductIds.remove(productId)
        } else {
            selectedProductIds.insert(productId)
        }
    }

    func saveOutfit() {
        // TODO: Replace with dataStore.createLookBuilderOutfit() / update
        let outfit = LookBuilderOutfit(
            id: editingOutfit?.id ?? UUID(),
            associateId: UUID(),
            clientId: selectedClientId,
            name: outfitName.trimmingCharacters(in: .whitespaces),
            productIds: Array(selectedProductIds),
            imageURL: nil,
            notes: outfitNotes.isEmpty ? nil : outfitNotes,
            createdAt: editingOutfit?.createdAt ?? .now
        )

        if let existing = editingOutfit,
           let idx = outfits.firstIndex(where: { $0.id == existing.id }) {
            outfits[idx] = outfit
        } else {
            outfits.insert(outfit, at: 0)
        }

        isShowingEditor = false
    }

    func deleteOutfit(at offsets: IndexSet) {
        outfits.remove(atOffsets: offsets)
    }

    // MARK: - Helpers

    func clientName(for id: UUID?) -> String {
        guard let id else { return "No Client" }
        return clients.first { $0.id == id }?.fullName ?? "Unknown"
    }

    func productName(for id: UUID) -> String {
        products.first { $0.id == id }?.name ?? "Unknown Product"
    }

    func product(by id: UUID) -> Product? {
        products.first { $0.id == id }
    }
}
