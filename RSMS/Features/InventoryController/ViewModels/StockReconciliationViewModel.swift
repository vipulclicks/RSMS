//
//  StockReconciliationViewModel.swift
//  RSMS
//
//  ViewModel for the "Stock Reconciliation" screen.
//  Manages discrepancy items, audit history, and reconciliation state.
//

import SwiftUI
import Observation

// MARK: - Reconciliation Status

enum ReconciliationStatus: String, CaseIterable {
    case pending     = "Pending"
    case underReview = "Under Review"
    case resolved    = "Resolved"

    var color: Color {
        switch self {
        case .pending:     return RSMSTheme.warning
        case .underReview: return RSMSTheme.info
        case .resolved:    return RSMSTheme.success
        }
    }
}

// MARK: - Adjustment Reason

enum AdjustmentReason: String, CaseIterable, Identifiable {
    case damagedItem       = "Damaged item"
    case theftLoss         = "Theft / loss"
    case scanningError     = "Scanning error"
    case supplierIssue     = "Supplier issue"
    case misplacedInventory = "Misplaced inventory"

    var id: String { rawValue }
}

// MARK: - Discrepancy Item

struct DiscrepancyItem: Identifiable, Hashable {
    let id: UUID
    let product: Product
    let expectedQty: Int
    var actualQty: Int
    var variance: Int
    var status: ReconciliationStatus
    let lastUpdated: Date

    var icon: String {
        switch product.category {
        case "Watches":  return "watch.analog"
        case "Handbags": return "handbag.fill"
        case "Jewelry":  return "sparkles"
        case "Heels":    return "shoe.fill"
        default:         return "shippingbox.fill"
        }
    }
}

// MARK: - Audit Log Entry

struct ReconciliationAuditEntry: Identifiable {
    let id: UUID
    let userName: String
    let timestamp: Date
    let productName: String
    let previousQty: Int
    let updatedQty: Int
    let reason: AdjustmentReason
}

// MARK: - ViewModel

@Observable
final class StockReconciliationViewModel {

    // MARK: - State

    var discrepancyItems: [DiscrepancyItem] = []
    var auditEntries: [ReconciliationAuditEntry] = []
    var searchText: String = ""
    var filterStatus: ReconciliationStatus? = nil

    // Reconciliation modal state
    var correctedQty: String = ""
    var selectedReason: AdjustmentReason? = nil
    var adjustmentNotes: String = ""
    var isReconciling = false

    // Success state
    var showSuccessModal = false
    var reconciledOldQty: Int = 0
    var reconciledNewQty: Int = 0
    var reconciledTimestamp: Date = .now

    // MARK: - Computed Properties

    var totalDiscrepancies: Int {
        discrepancyItems.count
    }

    var pendingVerification: Int {
        discrepancyItems.filter { $0.status == .pending || $0.status == .underReview }.count
    }

    var resolvedToday: Int {
        discrepancyItems.filter { $0.status == .resolved }.count
    }

    var auditLogsUpdated: Int {
        auditEntries.count
    }

    var filteredItems: [DiscrepancyItem] {
        var items = discrepancyItems
        if let filterStatus {
            items = items.filter { $0.status == filterStatus }
        }
        if !searchText.isEmpty {
            items = items.filter {
                $0.product.name.localizedCaseInsensitiveContains(searchText) ||
                $0.product.sku.localizedCaseInsensitiveContains(searchText)
            }
        }
        return items
    }

    // MARK: - Live Data Load

    var totalStoreInventoryValue: Double = 0.0
    var shrinkageValue: Double = 0.0
    var shrinkagePercentage: Double {
        guard totalStoreInventoryValue > 0 else { return 0 }
        return (shrinkageValue / totalStoreInventoryValue) * 100
    }

    func load(from dataStore: DataStore, storeId: UUID) {
        let variances = dataStore.inventoryVariances.filter { $0.storeId == storeId }
        
        self.discrepancyItems = variances.compactMap { variance in
            guard let product = dataStore.product(by: variance.productId) else { return nil }
            let rStatus: ReconciliationStatus
            switch variance.status {
            case .open: rStatus = .pending
            case .investigating: rStatus = .underReview
            case .resolved, .writeOff: rStatus = .resolved
            }
            return DiscrepancyItem(
                id: variance.id,
                product: product,
                expectedQty: variance.expectedQty,
                actualQty: variance.actualQty,
                variance: variance.variance,
                status: rStatus,
                lastUpdated: variance.reportedAt
            )
        }.sorted { $0.lastUpdated > $1.lastUpdated }
        
        let audits = dataStore.auditTrails.filter { $0.storeId == storeId && $0.action.contains("Reconciliation") }
        self.auditEntries = audits.compactMap { audit in
            let user = dataStore.user(by: audit.performedBy)
            return ReconciliationAuditEntry(
                id: audit.id,
                userName: user?.fullName ?? "Unknown",
                timestamp: audit.timestamp,
                productName: dataStore.productName(for: audit.entityId),
                previousQty: 0,
                updatedQty: 0,
                reason: .scanningError
            )
        }.sorted { $0.timestamp > $1.timestamp }
        
        // Shrinkage calculations
        let storeItems = dataStore.stockItems.filter { $0.storeId == storeId }
        self.totalStoreInventoryValue = storeItems.reduce(0.0) { sum, stock in
            guard let product = dataStore.product(by: stock.productId) else { return sum }
            return sum + (Double(stock.quantity) * product.price)
        }
        
        self.shrinkageValue = self.discrepancyItems.reduce(0.0) { sum, item in
            if item.actualQty < item.expectedQty {
                let missing = item.expectedQty - item.actualQty
                return sum + (Double(missing) * item.product.price)
            }
            return sum
        }
    }

    // MARK: - Actions

    func reconcile(item: DiscrepancyItem) {
        guard let qty = Int(correctedQty.trimmingCharacters(in: .whitespacesAndNewlines)), let reason = selectedReason else { return }

        isReconciling = true
        reconciledOldQty = item.actualQty
        reconciledNewQty = qty
        reconciledTimestamp = .now

        if let index = discrepancyItems.firstIndex(where: { $0.id == item.id }) {
            discrepancyItems[index].actualQty = qty
            discrepancyItems[index].variance = qty - item.expectedQty
            discrepancyItems[index].status = .resolved
        }

        // Add audit entry
        let entry = ReconciliationAuditEntry(
            id: UUID(),
            userName: "Emma Leroy",
            timestamp: .now,
            productName: item.product.name,
            previousQty: item.actualQty,
            updatedQty: qty,
            reason: reason
        )
        auditEntries.insert(entry, at: 0)

        // Reset form
        correctedQty = ""
        selectedReason = nil
        adjustmentNotes = ""
        isReconciling = false

        showSuccessModal = true
    }

    func resetReconcileForm() {
        correctedQty = ""
        selectedReason = nil
        adjustmentNotes = ""
    }
}
