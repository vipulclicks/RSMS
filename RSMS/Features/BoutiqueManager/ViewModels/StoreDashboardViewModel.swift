//
//  StoreDashboardViewModel.swift
//  RSMS
//

import SwiftUI

@Observable
final class StoreDashboardViewModel {

    // MARK: - Data
    // TODO: Replace mock data with Supabase fetch
    private(set) var summary: DashboardSummary = .preview
    private(set) var shifts: [StaffShift] = StaffShift.all
    private(set) var store: Store = .preview

    // MARK: - Formatting

    var formattedDate: String {
        RSMSDateFormatter.fullDate.string(from: .now)
    }

    func formatCurrency(_ value: Double) -> String {
        "₹\(String(format: "%,.0f", value))"
    }

    func staffName(for id: UUID) -> String {
        UserProfile.all.first(where: { $0.id == id })?.fullName ?? "Unknown"
    }
}
