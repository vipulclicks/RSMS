//
//  LookbookViewModel.swift
//  RSMS
//

import SwiftUI

@Observable
final class LookbookViewModel {
    var lookbooks: [Lookbook] = []
    var isLoading = false
    var errorMessage: String?

    @MainActor
    func load(dataStore: DataStore) async {
        isLoading = true
        errorMessage = nil

        do {
            try await dataStore.fetchLookbooks()
            lookbooks = dataStore.lookbooks
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    func create(
        title: String,
        pdfStoragePath: String?,
        dataStore: DataStore
    ) async {
        let lookbook = Lookbook(
            id: UUID(),
            title: title,
            isActive: true,
            createdAt: .now,
            pdfStoragePath: pdfStoragePath
        )

        do {
            let created = try await dataStore.createLookbook(lookbook)
            lookbooks.insert(created, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func update(_ lookbook: Lookbook, dataStore: DataStore) async {
        do {
            let updated = try await dataStore.updateLookbook(lookbook)
            if let index = lookbooks.firstIndex(where: { $0.id == updated.id }) {
                lookbooks[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func delete(id: UUID, dataStore: DataStore) async {
        do {
            try await dataStore.deleteLookbook(id: id)
            lookbooks.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
