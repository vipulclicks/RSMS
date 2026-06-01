//
//  StockReconciliationViewModel.swift
//  RSMS
//
//  ViewModel for the "Stock Reconciliation" screen.
//  Manages discrepancy items, audit history, and reconciliation state.
//  All data sourced from Supabase via DataStore — no hardcoded values.
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
    case damagedItem        = "Damaged item"
    case theftLoss          = "Theft / loss"
    case scanningError      = "Scanning error"
    case supplierIssue      = "Supplier issue"
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
        switch product.category.lowercased() {
        case "watches":               return "watch.analog"
        case "handbags", "leather goods": return "handbag.fill"
        case "jewelry", "jewellery":  return "sparkles"
        case "shoes", "heels":        return "shoe.fill"
        case "accessories":           return "eyeglasses"
        case "fragrances":            return "bubbles.and.sparkles"
        default:                      return "shippingbox.fill"
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
    var isLoading = false
    var loadError: String? = nil

    // Shrinkage from Supabase shrinkage_analytics table
    var shrinkageRecord: ShrinkageAnalytics? = nil

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

    var totalDiscrepancies: Int { discrepancyItems.count }

    var pendingVerification: Int {
        discrepancyItems.filter { $0.status == .pending || $0.status == .underReview }.count
    }

    var resolvedToday: Int {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return discrepancyItems.filter { $0.status == .resolved && $0.lastUpdated >= startOfDay }.count
    }

    var auditLogsUpdated: Int { auditEntries.count }

    var filteredItems: [DiscrepancyItem] {
        // Exclude resolved items from the mismatches view
        var items = discrepancyItems.filter { $0.status != .resolved }
        
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

    // MARK: - Computed shrinkage from live variance data

    var baseInventoryValue: Double = 0.0

    var totalStoreInventoryValue: Double {
        return baseInventoryValue
    }

    var shrinkageValue: Double {
        discrepancyItems.reduce(0.0) { sum, item in
            guard item.actualQty < item.expectedQty else { return sum }
            let missing = item.expectedQty - item.actualQty
            return sum + (Double(missing) * item.product.price)
        }
    }

    var shrinkagePercentage: Double {
        guard totalStoreInventoryValue > 0 else { return 0 }
        return (shrinkageValue / totalStoreInventoryValue) * 100
    }

    // MARK: - Live Data Load (async — fetches from Supabase)

    @MainActor
    func load(from dataStore: DataStore, storeId: UUID) async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            // Fetch all required tables in parallel
            async let _ = dataStore.fetchInventoryVariances(storeId: storeId)
            async let _ = dataStore.fetchAuditTrails(storeId: storeId)
            async let _ = dataStore.fetchShrinkageAnalytics(storeId: storeId)
            async let _ = dataStore.fetchStockItems(storeId: storeId)
            async let _ = dataStore.fetchProducts()
            async let _ = dataStore.fetchUsers()

            // Await all
            try await dataStore.fetchInventoryVariances(storeId: storeId)
            try await dataStore.fetchAuditTrails(storeId: storeId)
            try await dataStore.fetchShrinkageAnalytics(storeId: storeId)
            try await dataStore.fetchStockItems(storeId: storeId)
            if dataStore.products.isEmpty {
                try await dataStore.fetchProducts()
            }
            if dataStore.users.isEmpty {
                try await dataStore.fetchUsers()
            }
        } catch {
            loadError = error.localizedDescription
        }

        buildDiscrepancyItems(from: dataStore, storeId: storeId)
        buildAuditEntries(from: dataStore, storeId: storeId)
        buildShrinkageData(from: dataStore, storeId: storeId)
    }

    // MARK: - Private builders (run after fetch)

    private func buildDiscrepancyItems(from dataStore: DataStore, storeId: UUID) {
        let variances = dataStore.inventoryVariances.filter { $0.storeId == storeId }
        self.discrepancyItems = variances.compactMap { variance in
            guard let product = dataStore.product(by: variance.productId) else { return nil }
            let rStatus: ReconciliationStatus
            switch variance.status {
            case .open:          rStatus = .pending
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
    }

    private func buildAuditEntries(from dataStore: DataStore, storeId: UUID) {
        // Filter audit trails relevant to reconciliation actions
        let reconciliationActions: Set<String> = [
            "Stock Adjusted", "Variance Reported", "Reconciliation"
        ]
        let audits = dataStore.auditTrails.filter { audit in
            audit.storeId == storeId &&
            reconciliationActions.contains(where: { audit.action.contains($0) })
        }
        self.auditEntries = audits.compactMap { audit in
            let user = dataStore.user(by: audit.performedBy)
            // Parse structured details string: "prev: X | new: Y | reason: Z" if present
            // Otherwise default — columns will be added later to support richer data
            let (prev, new, reason) = parseAuditDetails(audit.details)
            return ReconciliationAuditEntry(
                id: audit.id,
                userName: user?.fullName ?? "Unknown User",
                timestamp: audit.timestamp,
                productName: dataStore.productName(for: audit.entityId),
                previousQty: prev,
                updatedQty: new,
                reason: reason
            )
        }.sorted { $0.timestamp > $1.timestamp }
    }

    private func buildShrinkageData(from dataStore: DataStore, storeId: UUID) {
        // Most recent shrinkage record for this store
        self.shrinkageRecord = dataStore.shrinkageAnalytics
            .filter { $0.storeId == storeId }
            .sorted { $0.periodEnd > $1.periodEnd }
            .first

        // Compute live values from current stock and variances
        let storeItems = dataStore.stockItems.filter { $0.storeId == storeId }
        self.baseInventoryValue = storeItems.reduce(0.0) { sum, stock in
            guard let product = dataStore.product(by: stock.productId) else { return sum }
            return sum + (Double(stock.quantity) * product.price)
        }
    }

    /// Parses a structured details string written by `reconcile()`.
    /// Format: "SKU: X · Name | prev: P | new: N | reason: R"
    private func parseAuditDetails(_ details: String?) -> (Int, Int, AdjustmentReason) {
        guard let details else { return (0, 0, .scanningError) }
        var prev = 0, new = 0
        var reason: AdjustmentReason = .scanningError
        let parts = details.components(separatedBy: " | ")
        for part in parts {
            if part.hasPrefix("prev: "), let v = Int(part.dropFirst(6)) { prev = v }
            if part.hasPrefix("new: "),  let v = Int(part.dropFirst(5)) { new = v }
            if part.hasPrefix("reason: ") {
                let r = String(part.dropFirst(8))
                reason = AdjustmentReason.allCases.first { $0.rawValue == r } ?? .scanningError
            }
        }
        return (prev, new, reason)
    }

    // MARK: - Actions

    /// Reconciles a discrepancy item. Requires the current user to attribute the change.
    func reconcile(item: DiscrepancyItem, currentUser: UserProfile?, dataStore: DataStore) {
        guard let qty = Int(correctedQty.trimmingCharacters(in: .whitespacesAndNewlines)),
              let reason = selectedReason else { return }

        isReconciling = true
        reconciledOldQty = item.actualQty
        reconciledNewQty = qty
        reconciledTimestamp = .now

        if let index = discrepancyItems.firstIndex(where: { $0.id == item.id }) {
            discrepancyItems[index].actualQty = qty
            discrepancyItems[index].variance = qty - item.expectedQty
            discrepancyItems[index].status = .resolved
        }

        // Build audit entry using current user from AppViewModel
        let userName = currentUser?.fullName ?? "Unknown User"
        let entry = ReconciliationAuditEntry(
            id: UUID(),
            userName: userName,
            timestamp: .now,
            productName: item.product.name,
            previousQty: item.actualQty,
            updatedQty: qty,
            reason: reason
        )
        auditEntries.insert(entry, at: 0)

        // Write structured details to Supabase audit trail
        if let storeId = currentUser?.storeId {
            let details = "SKU: \(item.product.sku) · \(item.product.name) | prev: \(item.actualQty) | new: \(qty) | reason: \(reason.rawValue)"
            dataStore.logAudit(
                storeId: storeId,
                action: "Stock Adjusted",
                entityType: "InventoryVariance",
                entityId: item.id,
                performedBy: currentUser!.id,
                details: details
            )
        }

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
