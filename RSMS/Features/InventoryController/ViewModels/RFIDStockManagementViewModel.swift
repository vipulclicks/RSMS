//
//  RFIDStockManagementViewModel.swift
//  RSMS
//

import SwiftUI

@Observable
final class RFIDStockManagementViewModel {

    // MARK: - Data
    // TODO: Replace mock data with Supabase fetch
    private(set) var stockItem: StockItem = .preview
    private(set) var scanRecord: RFIDScanRecord = .preview
    private(set) var discrepancy: StockDiscrepancy = .preview
    private(set) var shrinkage: ShrinkageAnalytics = .preview
    private(set) var products: [Product] = Product.all

    // MARK: - Computed

    var trackedProduct: Product? {
        products.first(where: { $0.id == stockItem.productId })
    }

    var discrepancyProduct: Product? {
        products.first(where: { $0.id == discrepancy.productId })
    }

    var stockVariance: Int {
        discrepancy.actualQty - discrepancy.expectedQty
    }

    // MARK: - Formatting

    func timeAgo(from date: Date) -> String {
        RSMSDateFormatter.timeAgo(from: date)
    }

    // MARK: - Color Mapping

    func stockStatusColor(_ status: StockStatus) -> Color {
        switch status {
        case .available: return RSMSTheme.success
        case .reserved:  return RSMSTheme.warning
        case .sold:      return RSMSTheme.textSecondary
        case .inTransit: return RSMSTheme.info
        case .damaged:   return RSMSTheme.danger
        case .onLoan:    return RSMSTheme.warning
        }
    }

    func discrepancyStatusColor(_ status: DiscrepancyStatus) -> Color {
        switch status {
        case .open:          return RSMSTheme.danger
        case .investigating: return RSMSTheme.warning
        case .resolved:      return RSMSTheme.success
        case .writeOff:      return RSMSTheme.textSecondary
        }
    }
}
