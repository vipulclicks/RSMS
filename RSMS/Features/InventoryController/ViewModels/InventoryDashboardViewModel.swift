//
//  InventoryDashboardViewModel.swift
//  RSMS
//
//  Fetches live data from Supabase and computes all KPIs shown on the
//  Inventory Controller home dashboard. Replaces the hardcoded preview snapshot.
//

import SwiftUI

@Observable
final class InventoryDashboardViewModel {

    // MARK: - State

    var snapshot: InventoryDashboardSnapshot = .preview
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // MARK: - Load

    /// Parallel-fetches all required Supabase tables, then computes the snapshot.
    @MainActor
    func load(dataStore: DataStore, storeId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Fetch all 4 tables concurrently
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await dataStore.fetchProducts() }
                group.addTask { try await dataStore.fetchStockItems(storeId: storeId) }
                group.addTask { try await dataStore.fetchAuditTrails(storeId: storeId) }
                group.addTask { try await dataStore.fetchInventoryVariances(storeId: storeId) }
                try await group.waitForAll()
            }
            snapshot = buildSnapshot(from: dataStore, storeId: storeId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Snapshot Builder

    private func buildSnapshot(from dataStore: DataStore, storeId: UUID) -> InventoryDashboardSnapshot {
        let calendar = Calendar.current

        // ── Total Inventory ──────────────────────────────────────────────────
        // Sum of every stock item's quantity at this store.
        let totalInventory = dataStore.stockItems
            .filter { $0.storeId == storeId }
            .reduce(0) { $0 + $1.quantity }

        // ── Today's Scans ────────────────────────────────────────────────────
        // Audit trail rows created today whose action contains "Barcode Scan".
        let todayScans = dataStore.auditTrails.filter {
            calendar.isDateInToday($0.timestamp) &&
            $0.action.localizedCaseInsensitiveContains("Barcode Scan")
        }.count

        // ── Scan Completion % ────────────────────────────────────────────────
        // Fraction of the product catalogue touched today, capped at 100%.
        let productCount = max(1, dataStore.products.count)
        let scanPercent = min(1.0, Double(todayScans) / Double(productCount))

        // ── Low Stock ────────────────────────────────────────────────────────
        // Available items whose quantity has dropped to 5 or below.
        let lowStockItems = dataStore.stockItems.filter {
            $0.storeId == storeId &&
            $0.status == .available &&
            $0.quantity <= 5
        }
        // Items that became low-stock today (updated_at is today).
        let newLowStockToday = lowStockItems.filter {
            calendar.isDateInToday($0.updatedAt)
        }.count

        // ── Pending Tasks ────────────────────────────────────────────────────
        // Open or investigating inventory variances for this store.
        let pendingVariances = dataStore.inventoryVariances.filter {
            $0.storeId == storeId &&
            ($0.status == .open || $0.status == .investigating)
        }.count

        // ── Recent Activity ──────────────────────────────────────────────────
        // Ten most recent audit trail entries for this store.
        let recentActivity = dataStore.auditTrails
            .filter { $0.storeId == storeId }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(10)
            .map { $0 }

        return InventoryDashboardSnapshot(
            totalInventoryCount:  totalInventory,
            todaysScanCount:      todayScans,
            scanCompletionPercent: scanPercent,
            lowStockAlertCount:   lowStockItems.count,
            newLowStockCount:     newLowStockToday,
            pendingTaskCount:     pendingVariances,
            recentActivity:       recentActivity
        )
    }
}
