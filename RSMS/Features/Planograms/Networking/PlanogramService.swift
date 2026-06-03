//
//  PlanogramService.swift
//  RSMS
//

import Foundation

/// A dedicated service layer for Planograms that wraps SupabaseClient
@MainActor
final class PlanogramService {
    static let shared = PlanogramService()
    
    private let api = SupabaseClient.shared
    
    private init() {}
    
    // MARK: - Planograms
    
    func fetchPlanograms(storeId: UUID? = nil) async throws -> [Planogram] {
        var query: [String: String] = [:]
        if let storeId {
            query["store_id"] = "eq.\(storeId.uuidString)"
        }
        return try await api.fetch("planograms", query: query)
    }
    
    func createPlanogram(_ planogram: Planogram) async throws -> Planogram {
        return try await api.insert("planograms", record: planogram)
    }
    
    func updatePlanogram(_ planogram: Planogram) async throws -> Planogram {
        return try await api.update("planograms", id: planogram.id, record: planogram)
    }
    
    // MARK: - Items
    
    func fetchItems(for planogramId: UUID) async throws -> [PlanogramItem] {
        let query = ["planogram_id": "eq.\(planogramId.uuidString)"]
        return try await api.fetch("planogram_items", query: query)
    }
    
    func saveItem(_ item: PlanogramItem) async throws -> PlanogramItem {
        return try await api.insert("planogram_items", record: item)
    }
    
    func deleteItem(id: UUID) async throws {
        try await api.delete("planogram_items", id: id)
    }
    
    func deleteItems(for planogramId: UUID) async throws {
        // Technically, you'd use a match filter. For now, fetch and delete to be safe.
        let items = try await fetchItems(for: planogramId)
        for item in items {
            try await deleteItem(id: item.id)
        }
    }
    
    // MARK: - Versions
    
    func fetchVersions(for planogramId: UUID) async throws -> [PlanogramVersion] {
        let query = ["planogram_id": "eq.\(planogramId.uuidString)", "order": "created_at.desc"]
        return try await api.fetch("planogram_versions", query: query)
    }
    
    func publishPlanogram(planogramId: UUID) async throws -> PlanogramVersion {
        let version = PlanogramVersion(
            id: UUID(),
            planogramId: planogramId,
            status: .published,
            publishedAt: Date(),
            createdBy: nil,
            createdAt: Date()
        )
        return try await api.insert("planogram_versions", record: version)
    }
    
    // MARK: - Merchandising Zones
    
    func fetchZones(for storeId: UUID) async throws -> [MerchandisingZone] {
        let query = ["store_id": "eq.\(storeId.uuidString)"]
        return try await api.fetch("merchandising_zones", query: query)
    }
    
    func createZone(_ zone: MerchandisingZone) async throws -> MerchandisingZone {
        return try await api.insert("merchandising_zones", record: zone)
    }
    
    func updateZone(_ zone: MerchandisingZone) async throws -> MerchandisingZone {
        return try await api.update("merchandising_zones", id: zone.id, record: zone)
    }
    
    func deleteZone(id: UUID) async throws {
        try await api.delete("merchandising_zones", id: id)
    }
}
