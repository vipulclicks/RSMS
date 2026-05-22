//
//  StoreDashboardViewModel.swift
//  RSMS
//
//  Fetches live store data from Supabase and computes KPIs for the
//  Boutique Manager dashboard. Replaces hardcoded preview data.
//

import SwiftUI

// MARK: - Low Stock Alert Model

struct LowStockAlert: Identifiable, Hashable {
    let id: UUID
    let product: Product
    let stockItem: StockItem

    static func == (lhs: LowStockAlert, rhs: LowStockAlert) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

@Observable
final class StoreDashboardViewModel {

    // MARK: - State
    private(set) var summary: DashboardSummary? = nil
    private(set) var shifts: [StaffShift] = []
    private(set) var store: Store? = nil
    var lowStockAlerts: [LowStockAlert] = []
    var isLoading = false
    var errorMessage: String? = nil

    // MARK: - Formatting

    var formattedDate: String {
        RSMSDateFormatter.fullDate.string(from: .now)
    }

    func formatCurrency(_ value: Double) -> String {
        "₹\(String(format: "%,.0f", value))"
    }

    func staffName(for id: UUID, from dataStore: DataStore) -> String {
        dataStore.users.first(where: { $0.id == id })?.fullName ?? "Unknown"
    }

    func reorderItem(for productId: UUID) {
        lowStockAlerts.removeAll { $0.product.id == productId }
    }

    // MARK: - Load

    @MainActor
    func load(dataStore: DataStore, storeId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await dataStore.fetchStore(id: storeId).map { _ in () } ?? () }
                group.addTask { try await dataStore.fetchDashboardSummaries(storeId: storeId) }
                group.addTask { try await dataStore.fetchStaffShifts(storeId: storeId) }
                group.addTask { try await dataStore.fetchStockItems(storeId: storeId) }
                group.addTask { try await dataStore.fetchProducts() }
                group.addTask { try await dataStore.fetchUsers(storeId: storeId) }
                try await group.waitForAll()
            }

            store = dataStore.stores.first { $0.id == storeId }
            summary = dataStore.dashboardSummaries.first { $0.storeId == storeId }
            shifts = dataStore.staffShifts.filter { $0.storeId == storeId }

            // Compute low-stock alerts from live stock items
            let storeItems = dataStore.stockItems.filter { $0.storeId == storeId && $0.quantity <= 5 && $0.status == .available }
            lowStockAlerts = storeItems.compactMap { item in
                guard let product = dataStore.products.first(where: { $0.id == item.productId }) else { return nil }
                return LowStockAlert(id: item.id, product: product, stockItem: item)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Helper: optional-returning fetchStore

private extension DataStore {
    func fetchStore(id: UUID) async throws -> Store? {
        if stores.first(where: { $0.id == id }) == nil {
            try await fetchStores()
        }
        return stores.first { $0.id == id }
    }
}
