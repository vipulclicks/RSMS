//
//  ComplianceAuditViewModel.swift
//  RSMS
//
//  ViewModel for the Compliance & Audit screen.
//  CRUD for cycle counts, inventory variances, and audit trails.
//

import SwiftUI

@Observable
final class ComplianceAuditViewModel {

    private let dataStore: DataStore
    private let storeId: UUID
    private let userId: UUID

    var isLoading = false
    var errorMessage: String?

    init(dataStore: DataStore, storeId: UUID, userId: UUID) {
        self.dataStore = dataStore
        self.storeId   = storeId
        self.userId    = userId
    }

    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchProducts()
            try await dataStore.fetchUsers(storeId: storeId)
            try await dataStore.fetchCycleCounts(storeId: storeId)
            try await dataStore.fetchInventoryVariances(storeId: storeId)
            try await dataStore.fetchAuditTrails(storeId: storeId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Cycle Counts
    var cycleCounts: [CycleCount] { dataStore.cycleCounts.filter { $0.storeId == storeId } }
    var scheduledCounts: [CycleCount] { cycleCounts.filter { $0.status == .scheduled } }
    var completedCounts: [CycleCount] { cycleCounts.filter { $0.status == .completed } }

    func scheduleCycleCount(date: Date, notes: String?) async throws {
        let cc = CycleCount(
            id: UUID(), storeId: storeId, scheduledDate: date,
            status: .scheduled, conductedBy: nil, completedAt: nil,
            notes: notes, createdAt: .now
        )
        try await dataStore.createCycleCount(cc)
        dataStore.logAudit(storeId: storeId, action: "Cycle Count Scheduled", entityType: "CycleCount", entityId: cc.id, performedBy: userId)
    }

    func startCycleCount(_ cc: CycleCount) async throws {
        let started = CycleCount(
            id: cc.id, storeId: cc.storeId, scheduledDate: cc.scheduledDate,
            status: .inProgress, conductedBy: userId, completedAt: nil,
            notes: cc.notes, createdAt: cc.createdAt
        )
        try await dataStore.updateCycleCount(started)
    }

    func completeCycleCount(_ cc: CycleCount) async throws {
        let done = CycleCount(
            id: cc.id, storeId: cc.storeId, scheduledDate: cc.scheduledDate,
            status: .completed, conductedBy: cc.conductedBy ?? userId,
            completedAt: .now, notes: cc.notes, createdAt: cc.createdAt
        )
        try await dataStore.updateCycleCount(done)
        dataStore.logAudit(storeId: storeId, action: "Cycle Count Completed", entityType: "CycleCount", entityId: cc.id, performedBy: userId)
    }

    func cancelCycleCount(id: UUID) async throws {
        try await dataStore.deleteCycleCount(id: id)
    }

    // MARK: - Variances (linked to cycle counts)
    var variances: [InventoryVariance] { dataStore.inventoryVariances.filter { $0.storeId == storeId } }
    var openVariances: [InventoryVariance] { variances.filter { $0.status == .open || $0.status == .investigating } }

    func reportVariance(productId: UUID, expected: Int, actual: Int, cycleCountId: UUID?) async throws {
        let v = InventoryVariance(
            id: UUID(), storeId: storeId, productId: productId,
            expectedQty: expected, actualQty: actual, variance: actual - expected,
            reportedBy: userId, status: .open, cycleCountId: cycleCountId,
            resolution: nil, reportedAt: .now, resolvedAt: nil
        )
        try await dataStore.createInventoryVariance(v)
    }

    func resolveVariance(_ v: InventoryVariance, resolution: String) async throws {
        let resolved = InventoryVariance(
            id: v.id, storeId: v.storeId, productId: v.productId,
            expectedQty: v.expectedQty, actualQty: v.actualQty, variance: v.variance,
            reportedBy: v.reportedBy, status: .resolved, cycleCountId: v.cycleCountId,
            resolution: resolution, reportedAt: v.reportedAt, resolvedAt: .now
        )
        try await dataStore.updateInventoryVariance(resolved)
    }

    // MARK: - Audit Trail
    var auditTrails: [AuditTrail] {
        dataStore.auditTrails.filter { $0.storeId == storeId }.sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Helpers
    func productName(for id: UUID) -> String { dataStore.productName(for: id) }
    func userName(for id: UUID) -> String { dataStore.userName(for: id) }

    func cycleCountStatusColor(_ status: CycleCountStatus) -> Color {
        switch status {
        case .scheduled:  return RSMSTheme.info
        case .inProgress: return RSMSTheme.warning
        case .completed:  return RSMSTheme.success
        case .cancelled:  return RSMSTheme.danger
        }
    }

    func varianceStatusColor(_ status: VarianceStatus) -> Color {
        switch status {
        case .open:          return RSMSTheme.danger
        case .investigating: return RSMSTheme.warning
        case .resolved:      return RSMSTheme.success
        case .writeOff:      return RSMSTheme.textSecondary
        }
    }
}
