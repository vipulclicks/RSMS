//
//  LookbookViewModel.swift
//  RSMS
//
//  ViewModel for digital lookbooks — fully connected to Supabase via DataStore.
//

import SwiftUI

@Observable
final class LookbookViewModel {

    // MARK: - Published State

    private(set) var allLookbooks: [Lookbook] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Filters

    var searchText = ""
    var selectedSeason: String? = nil
    var showArchived = false

    // MARK: - Computed

    /// All distinct seasons from the fetched lookbooks, sorted.
    var availableSeasons: [String] {
        let seasons = Set(allLookbooks.map { $0.season })
        return seasons.sorted()
    }

    /// Filtered lookbooks based on search, season, and active/archived toggle.
    var filteredLookbooks: [Lookbook] {
        var result = allLookbooks

        // Active vs Archived
        if !showArchived {
            result = result.filter { $0.isActive }
        }

        // Season filter
        if let season = selectedSeason, !season.isEmpty {
            result = result.filter { $0.season.lowercased() == season.lowercased() }
        }

        // Search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.season.lowercased().contains(query) ||
                ($0.description?.lowercased().contains(query) ?? false) ||
                ($0.brandGuideline?.lowercased().contains(query) ?? false)
            }
        }

        // Sort newest first
        return result.sorted { $0.createdAt > $1.createdAt }
    }

    /// Count of active lookbooks
    var activeCount: Int {
        allLookbooks.filter { $0.isActive }.count
    }

    /// Count of archived lookbooks
    var archivedCount: Int {
        allLookbooks.filter { !$0.isActive }.count
    }

    // MARK: - Data Loading

    @MainActor
    func load(dataStore: DataStore) async {
        isLoading = true
        errorMessage = nil

        do {
            try await dataStore.fetchLookbooks()
            self.allLookbooks = dataStore.lookbooks
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Refresh data from backend
    @MainActor
    func refresh(dataStore: DataStore) async {
        do {
            try await dataStore.fetchLookbooks()
            self.allLookbooks = dataStore.lookbooks
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Formatting

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
