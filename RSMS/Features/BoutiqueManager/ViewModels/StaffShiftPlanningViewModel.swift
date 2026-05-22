//
//  StaffShiftPlanningViewModel.swift
//  RSMS
//
//  Fetches live shift, goal, commission and performance data from Supabase.
//  Replaces hardcoded preview data.
//

import SwiftUI

@Observable
final class StaffShiftPlanningViewModel {

    // MARK: - State
    private(set) var shifts: [StaffShift] = []
    private(set) var goal: SalesGoal? = nil
    private(set) var commission: Commission? = nil
    private(set) var metric: PerformanceMetric? = nil
    var isLoading = false
    var errorMessage: String? = nil

    // MARK: - Load

    @MainActor
    func load(dataStore: DataStore, storeId: UUID, userId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await dataStore.fetchStaffShifts(storeId: storeId) }
                group.addTask { try await dataStore.fetchSalesGoals(storeId: storeId) }
                group.addTask { try await dataStore.fetchCommissions(staffId: userId) }
                group.addTask { try await dataStore.fetchPerformanceMetrics(storeId: storeId) }
                try await group.waitForAll()
            }

            shifts = dataStore.staffShifts.filter { $0.storeId == storeId }
            goal = dataStore.salesGoals.first { $0.storeId == storeId }
            commission = dataStore.commissions.first { $0.staffId == userId }
            metric = dataStore.performanceMetrics.first { $0.storeId == storeId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    func staffName(for id: UUID, from dataStore: DataStore) -> String {
        dataStore.users.first(where: { $0.id == id })?.fullName ?? "Staff"
    }

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

    var goalProgressRatio: Double {
        guard let g = goal, g.targetAmount > 0 else { return 0 }
        return g.achievedAmount / g.targetAmount
    }

    var goalAchievedPercent: Int {
        Int(goalProgressRatio * 100)
    }
}
