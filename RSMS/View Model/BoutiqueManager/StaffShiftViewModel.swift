//
//  StaffShiftViewModel.swift
//  RSMS
//
//  ViewModel for the Staff & Shift Planning screen.
//  CRUD for shifts, goals, commissions, and performance.
//

import SwiftUI

@Observable
final class StaffShiftViewModel {

    private let dataStore: DataStore
    private let storeId: UUID

    var selectedDate: Date = .now
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
            try await dataStore.fetchUsers(storeId: storeId)
            try await dataStore.fetchStaffShifts(storeId: storeId)
            try await dataStore.fetchSalesGoals(storeId: storeId)
            try await dataStore.fetchCommissions()
            try await dataStore.fetchPerformanceMetrics(storeId: storeId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Shifts
    var shifts: [StaffShift] { dataStore.staffShifts.filter { $0.storeId == storeId } }

    func createShift(_ shift: StaffShift) async throws {
        try await dataStore.createStaffShift(shift)
    }

    func updateShift(_ shift: StaffShift) async throws {
        try await dataStore.updateStaffShift(shift)
    }

    func deleteShift(id: UUID) async throws {
        try await dataStore.deleteStaffShift(id: id)
    }

    // MARK: - Sales Goals
    var salesGoals: [SalesGoal] { dataStore.salesGoals.filter { $0.storeId == storeId } }

    func createSalesGoal(_ goal: SalesGoal) async throws {
        try await dataStore.createSalesGoal(goal)
    }

    func updateSalesGoal(_ goal: SalesGoal) async throws {
        try await dataStore.updateSalesGoal(goal)
    }

    // MARK: - Commissions
    var commissions: [Commission] {
        let storeStaffIds = Set(dataStore.users.filter { $0.storeId == storeId }.map(\.id))
        return dataStore.commissions.filter { storeStaffIds.contains($0.staffId) }
    }

    // MARK: - Performance
    var performanceMetrics: [PerformanceMetric] {
        dataStore.performanceMetrics.filter { $0.storeId == storeId }
    }

    // MARK: - Helpers
    func staffName(for id: UUID) -> String { dataStore.userName(for: id) }

    func roleBadgeColor(_ role: String) -> Color {
        switch role {
        case "floor":       return RSMSTheme.success
        case "cashier":     return RSMSTheme.info
        case "back_office": return RSMSTheme.warning
        default:            return RSMSTheme.textSecondary
        }
    }

    func commissionColor(_ status: CommissionStatus) -> Color {
        switch status {
        case .pending:  return RSMSTheme.warning
        case .approved: return RSMSTheme.success
        case .paid:     return RSMSTheme.info
        }
    }
}
