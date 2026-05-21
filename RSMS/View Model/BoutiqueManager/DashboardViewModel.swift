//
//  DashboardViewModel.swift
//  RSMS
//
//  ViewModel for the Boutique Manager Store Dashboard.
//  Fetches dashboard summaries, shifts, and products from Supabase.
//

import SwiftUI

@Observable
final class DashboardViewModel {

    // MARK: - Dependencies
    private let dataStore: DataStore
    private let storeId: UUID

    // MARK: - State
    var isLoading = false
    var errorMessage: String?

    // MARK: - Init
    init(dataStore: DataStore, storeId: UUID) {
        self.dataStore = dataStore
        self.storeId   = storeId
    }

    // MARK: - Data Fetching
    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            try await dataStore.fetchStores()
            try await dataStore.fetchUsers(storeId: storeId)
            try await dataStore.fetchProducts()
            try await dataStore.fetchDashboardSummaries(storeId: storeId)
            try await dataStore.fetchStaffShifts(storeId: storeId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Dashboard Summary
    var summary: DashboardSummary? {
        dataStore.dashboardSummaries.first { $0.storeId == storeId }
    }

    var salesProgressPercent: Double {
        guard let s = summary, s.salesTarget > 0 else { return 0 }
        return s.salesActual / s.salesTarget
    }

    var salesRemaining: Double {
        guard let s = summary else { return 0 }
        return max(0, s.salesTarget - s.salesActual)
    }

    // MARK: - Staff
    var todayShifts: [StaffShift] {
        dataStore.staffShifts.filter { $0.storeId == storeId }
    }

    var staffOnDutyCount: Int { todayShifts.count }

    func staffName(for id: UUID) -> String { dataStore.userName(for: id) }

    // MARK: - Store
    var storeName: String { dataStore.storeName(for: storeId) }
    var store: Store? { dataStore.store(by: storeId) }

    // MARK: - Formatting
    func formatCurrency(_ value: Double) -> String { "€\(String(format: "%,.0f", value))" }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f.string(from: .now)
    }
}
