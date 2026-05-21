//
//  StaffShiftPlanningViewModel.swift
//  RSMS
//

import SwiftUI

@Observable
final class StaffShiftPlanningViewModel {

    // MARK: - Data
    // TODO: Replace mock data with Supabase fetch
    private(set) var shifts: [StaffShift] = StaffShift.all
    private(set) var goal: SalesGoal = .preview
    private(set) var commission: Commission = .preview
    private(set) var metric: PerformanceMetric = .preview

    // MARK: - Helpers

    func staffName(for id: UUID) -> String {
        UserProfile.all.first(where: { $0.id == id })?.fullName ?? "Staff"
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
        goal.achievedAmount / goal.targetAmount
    }

    var goalAchievedPercent: Int {
        Int(goalProgressRatio * 100)
    }
}
