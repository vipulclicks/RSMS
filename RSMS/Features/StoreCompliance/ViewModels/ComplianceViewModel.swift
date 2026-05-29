//
//  ComplianceViewModel.swift
//  RSMS
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class ComplianceViewModel {
    var complianceChecks: [ComplianceCheck] = []
    var availablePlanograms: [Planogram] = []
    
    var isLoading = false
    var isUploading = false
    var errorMessage: String?
    
    // Stats
    var overallComplianceRate: Double {
        guard !complianceChecks.isEmpty else { return 0 }
        let compliantCount = complianceChecks.filter { $0.status == .compliant }.count
        return Double(compliantCount) / Double(complianceChecks.count)
    }
    
    var compliantCount: Int {
        complianceChecks.filter { $0.status == .compliant }.count
    }
    
    var nonCompliantCount: Int {
        complianceChecks.filter { $0.status == .nonCompliant }.count
    }
    
    var needsReviewCount: Int {
        complianceChecks.filter { $0.status == .needsReview }.count
    }
    
    // Fetch Checks & Planograms
    func fetchChecks(for storeId: UUID? = nil) async {
        isLoading = true
        errorMessage = nil
        do {
            self.complianceChecks = try await ComplianceService.shared.fetchComplianceChecks(storeId: storeId)
            if let storeId = storeId {
                self.availablePlanograms = try await ComplianceService.shared.fetchPlanograms(storeId: storeId)
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("Failed to fetch compliance checks or planograms: \(error)")
        }
        isLoading = false
    }
    
    // Upload Photo
    func uploadPhoto(data: Data) async throws -> String {
        isUploading = true
        defer { isUploading = false }
        
        let fileName = UUID().uuidString + ".jpg"
        return try await ComplianceService.shared.uploadEvidencePhoto(data: data, fileName: fileName)
    }
    
    // Create
    func createCheck(_ check: ComplianceCheck) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let newCheck = try await ComplianceService.shared.createComplianceCheck(check)
        // Optimistic UI Update or just fetch again
        self.complianceChecks.append(newCheck)
    }
    
    // Update
    func updateCheck(_ check: ComplianceCheck) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let updatedCheck = try await ComplianceService.shared.updateComplianceCheck(id: check.id, check: check)
        
        if let index = complianceChecks.firstIndex(where: { $0.id == updatedCheck.id }) {
            complianceChecks[index] = updatedCheck
        }
    }
    
    // Delete
    func deleteCheck(_ id: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await ComplianceService.shared.deleteComplianceCheck(id: id)
        complianceChecks.removeAll { $0.id == id }
    }
}
