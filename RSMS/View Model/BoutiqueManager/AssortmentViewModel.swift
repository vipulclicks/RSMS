//
//  AssortmentViewModel.swift
//  RSMS
//
//  ViewModel for the Assortment & Visual Merchandising screen.
//  CRUD for planograms, lookbooks, and compliance checks.
//

import SwiftUI

@Observable
final class AssortmentViewModel {

    private let dataStore: DataStore
    private let storeId: UUID

    var isLoading = false
    var errorMessage: String?

    init(dataStore: DataStore, storeId: UUID) {
        self.dataStore = dataStore
        self.storeId   = storeId
    }

    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchPlanograms(storeId: storeId)
            try await dataStore.fetchLookbooks()
            try await dataStore.fetchComplianceChecks(storeId: storeId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Planograms
    var planograms: [Planogram] { dataStore.planograms.filter { $0.storeId == storeId } }
    var compliantCount: Int { planograms.filter(\.isCompliant).count }
    var nonCompliantCount: Int { planograms.count - compliantCount }

    func createPlanogram(_ p: Planogram) async throws { try await dataStore.createPlanogram(p) }
    func updatePlanogram(_ p: Planogram) async throws { try await dataStore.updatePlanogram(p) }
    func deletePlanogram(id: UUID) async throws { try await dataStore.deletePlanogram(id: id) }

    // MARK: - Lookbooks
    var lookbooks: [Lookbook] { dataStore.lookbooks }
    var activeLookbooks: [Lookbook] { lookbooks.filter(\.isActive) }

    func createLookbook(_ l: Lookbook) async throws { try await dataStore.createLookbook(l) }
    func updateLookbook(_ l: Lookbook) async throws { try await dataStore.updateLookbook(l) }
    func deleteLookbook(id: UUID) async throws { try await dataStore.deleteLookbook(id: id) }

    // MARK: - Compliance Checks
    var complianceChecks: [ComplianceCheck] { dataStore.complianceChecks.filter { $0.storeId == storeId } }

    func createComplianceCheck(_ c: ComplianceCheck) async throws { try await dataStore.createComplianceCheck(c) }

    func planogramName(for id: UUID) -> String {
        dataStore.planograms.first { $0.id == id }?.name ?? "Unknown"
    }

    func checkerName(for id: UUID) -> String { dataStore.userName(for: id) }

    func complianceColor(_ status: ComplianceStatus) -> Color {
        switch status {
        case .compliant:    return RSMSTheme.success
        case .nonCompliant: return RSMSTheme.danger
        case .needsReview:  return RSMSTheme.warning
        }
    }
}
