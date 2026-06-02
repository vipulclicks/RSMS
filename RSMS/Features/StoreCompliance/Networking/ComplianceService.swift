//
//  ComplianceService.swift
//  RSMS
//

import Foundation

@MainActor
final class ComplianceService {
    static let shared = ComplianceService()
    
    private init() {}
    
    // MARK: - CRUD Operations for compliance_checks
    
    func fetchComplianceChecks(storeId: UUID? = nil) async throws -> [ComplianceCheck] {
        if let storeId = storeId {
            return try await SupabaseClient.shared.fetch(
                "compliance_checks",
                query: ["store_id": "eq.\(storeId.uuidString)"]
            )
        } else {
            return try await SupabaseClient.shared.fetch("compliance_checks")
        }
    }
    
    func createComplianceCheck(_ check: ComplianceCheck) async throws -> ComplianceCheck {
        return try await SupabaseClient.shared.insert("compliance_checks", record: check)
    }
    
    func updateComplianceCheck(id: UUID, check: ComplianceCheck) async throws -> ComplianceCheck {
        return try await SupabaseClient.shared.update("compliance_checks", id: id, record: check)
    }
    
    
    func deleteComplianceCheck(id: UUID) async throws {
        try await SupabaseClient.shared.delete("compliance_checks", id: id)
    }
    
    // MARK: - Planograms Integration
    
    func fetchPlanograms(storeId: UUID) async throws -> [Planogram] {
        return try await SupabaseClient.shared.fetch(
            "planograms",
            query: ["store_id": "eq.\(storeId.uuidString)"]
        )
    }
    
    // MARK: - Storage
    
    func uploadEvidencePhoto(data: Data, fileName: String) async throws -> String {
        let path = try await SupabaseClient.shared.uploadStorage(
            bucket: "evidence",
            path: "checks/\(fileName)",
            data: data,
            contentType: "image/jpeg"
        )
        
        let publicEndpoint = SupabaseConfig.restURL.replacingOccurrences(of: "/rest/v1", with: "/storage/v1/object/public")
        return "\(publicEndpoint)/\(path)"
    }
}
