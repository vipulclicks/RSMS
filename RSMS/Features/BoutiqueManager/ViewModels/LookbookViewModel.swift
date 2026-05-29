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
    var isUploading = false
    var errorMessage: String?

    // MARK: - Filters

    var searchText = ""
    var showArchived = false

    // MARK: - Computed

    /// Filtered lookbooks based on search, season, and active/archived toggle.
    var filteredLookbooks: [Lookbook] {
        var result = allLookbooks

        // Active vs Archived
        if !showArchived {
            result = result.filter { $0.isActive }
        }

        // Search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query)
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
    
    // MARK: - Uploading
    
    @MainActor
    func uploadLookbook(title: String, fileURL: URL, dataStore: DataStore) async {
        isUploading = true
        errorMessage = nil
        
        let accessed = fileURL.startAccessingSecurityScopedResource()
        defer { if accessed { fileURL.stopAccessingSecurityScopedResource() } }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let fileName = "\(UUID().uuidString).pdf"
            
            // Upload to Supabase Storage
            let storagePath = try await SupabaseClient.shared.uploadStorage(bucket: "lookbooks", path: fileName, data: data, contentType: "application/pdf")
            
            let lookbook = Lookbook(id: UUID(), title: title, isActive: true, createdAt: .now, pdfStoragePath: storagePath)
            try await dataStore.createLookbook(lookbook)
            
            // Refresh
            self.allLookbooks = dataStore.lookbooks
        } catch {
            self.errorMessage = "Upload failed: \(error.localizedDescription)"
        }
        isUploading = false
    }

    // MARK: - Formatting

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
