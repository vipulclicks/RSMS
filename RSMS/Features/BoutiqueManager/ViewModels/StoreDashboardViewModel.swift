//
//  StoreDashboardViewModel.swift
//  RSMS
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

    // MARK: - Data
    // TODO: Replace mock data with Supabase fetch
    private(set) var summary: DashboardSummary = .preview
    private(set) var shifts: [StaffShift] = StaffShift.all
    private(set) var store: Store = .preview
    var lowStockAlerts: [LowStockAlert] = []

    // MARK: - Formatting

    var formattedDate: String {
        RSMSDateFormatter.fullDate.string(from: .now)
    }

    func formatCurrency(_ value: Double) -> String {
        "€\(String(format: "%,.0f", value))"
    }

    func staffName(for id: UUID) -> String {
        UserProfile.all.first(where: { $0.id == id })?.fullName ?? "Unknown"
    }

    func reorderItem(for productId: UUID) {
        lowStockAlerts.removeAll { $0.product.id == productId }
    }

    func simulateStockDrop() {
        // Demo helper: creates a sample low-stock alert for testing
        let alert = LowStockAlert(
            id: UUID(),
            product: .previewWatch,
            stockItem: .preview
        )
        if !lowStockAlerts.contains(where: { $0.product.id == alert.product.id }) {
            lowStockAlerts.append(alert)
        }
    }
}
