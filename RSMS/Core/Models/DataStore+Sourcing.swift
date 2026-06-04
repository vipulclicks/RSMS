//
//  DataStore+Sourcing.swift
//  RSMS
//

import Foundation

extension DataStore {
    
    @MainActor
    func fetchInventorySourcingRequests() async throws {
        self.inventorySourcingRequests = try await api.fetch("inventory_sourcing_requests")
    }
    
    @MainActor
    @discardableResult
    func createInventorySourcingRequest(_ request: InventorySourcingRequest) async throws -> InventorySourcingRequest {
        let created: InventorySourcingRequest = try await api.insert("inventory_sourcing_requests", record: request)
        self.inventorySourcingRequests.append(created)
        return created
    }
    
    @MainActor
    func updateInventorySourcingRequest(_ request: InventorySourcingRequest) async throws {
        try await api.update("inventory_sourcing_requests", id: request.id, record: request)
        if let idx = self.inventorySourcingRequests.firstIndex(where: { $0.id == request.id }) {
            self.inventorySourcingRequests[idx] = request
        }
    }
    
    @MainActor
    func deleteInventorySourcingRequest(id: UUID) async throws {
        do {
            try await api.delete("inventory_sourcing_requests", id: id)
        } catch {
            print("Supabase delete failed for inventory_sourcing_requests: \(error)")
        }
        self.inventorySourcingRequests.removeAll(where: { $0.id == id })
    }
}
