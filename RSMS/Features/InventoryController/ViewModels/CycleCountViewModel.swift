
import SwiftUI

@Observable
final class CycleCountViewModel {

    // MARK: - Published State

    var pendingItems: [CycleCountItem] = []
    var checkedItems: [CycleCountItem] = []
    var openVarianceItems: [InventoryVariance] = []
    var openMismatches: Int = 0
    var totalInventory: Int = 0
    var isLoading = false

    // Sheet state
    var itemToCount: CycleCountItem? = nil
    var enteredCount: String = ""
    var serialCode: String = ""
    var isSaving = false

    // MARK: - Load

    @MainActor
    func load(dataStore: DataStore, storeId: UUID?) async {
        isLoading = true
        defer { isLoading = false }

        // Refresh caches if empty
        if dataStore.products.isEmpty {
            try? await dataStore.fetchProducts()
        }
        if let sid = storeId, dataStore.stockItems.isEmpty {
            try? await dataStore.fetchStockItems(storeId: sid)
        }
        if let sid = storeId, dataStore.inventoryVariances.isEmpty {
            try? await dataStore.fetchInventoryVariances(storeId: sid)
        }

        let storeItems = storeId == nil
            ? dataStore.stockItems
            : dataStore.stockItems.filter { $0.storeId == storeId }

        totalInventory = storeItems.reduce(0) { $0 + $1.quantity }
        
        openVarianceItems = dataStore.inventoryVariances.filter { $0.status == .open }
        openMismatches = openVarianceItems.count

        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let thirtyDaysAgo = cutoff

        var pending: [CycleCountItem] = []
        var checked: [CycleCountItem] = []

        for item in storeItems {
            guard let product = dataStore.products.first(where: { $0.id == item.productId }) else { continue }

            let isPending: Bool
            if let lastScanned = item.lastScannedAt {
                isPending = lastScanned < thirtyDaysAgo
            } else {
                isPending = true
            }

            let entry = CycleCountItem(
                id: item.id,
                product: product,
                stockItem: item,
                expectedQty: item.quantity,
                lastChecked: item.lastScannedAt
            )

            if isPending {
                pending.append(entry)
            } else {
                checked.append(entry)
            }
        }

        // Sort pending: never-scanned first, then oldest scan
        pending.sort {
            let lhs = $0.stockItem.lastScannedAt ?? .distantPast
            let rhs = $1.stockItem.lastScannedAt ?? .distantPast
            return lhs < rhs
        }
        checked.sort {
            let lhs = $0.stockItem.lastScannedAt ?? .distantPast
            let rhs = $1.stockItem.lastScannedAt ?? .distantPast
            return lhs > rhs
        }

        self.pendingItems = pending
        self.checkedItems = checked
    }

    // MARK: - Submit Count

    @MainActor
    func submitCount(
        for item: CycleCountItem,
        dataStore: DataStore,
        user: UserProfile
    ) async {
        guard let actualQty = Int(enteredCount.trimmingCharacters(in: .whitespaces)) else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            // ✅ Write the physically-counted quantity back to the database.
            //    This is the core of cycle counting — the actual count
            //    becomes the new quantity of record.
            let updated = StockItem(
                id: item.stockItem.id,
                productId: item.stockItem.productId,
                storeId: item.stockItem.storeId,
                quantity: actualQty,           // ← use the actual physical count
                rfidTag: item.stockItem.rfidTag,
                location: item.stockItem.location,
                status: item.stockItem.status,
                lastScannedAt: .now,
                updatedAt: .now
            )
            try await dataStore.updateStockItem(updated)

            // Adjust the running totalInventory shown on the dashboard
            let delta = actualQty - item.expectedQty
            totalInventory = max(0, totalInventory + delta)

            // If count differs → log a variance record for the audit trail
            if actualQty != item.expectedQty, let storeId = user.storeId {
                let variance = InventoryVariance(
                    id: UUID(),
                    storeId: storeId,
                    productId: item.product.id,
                    expectedQty: item.expectedQty,
                    actualQty: actualQty,
                    variance: actualQty - item.expectedQty,
                    reportedBy: user.id,
                    status: .open,
                    cycleCountId: nil,
                    resolution: nil,
                    reportedAt: .now,
                    resolvedAt: nil
                )
                try await dataStore.createInventoryVariance(variance)
                openMismatches += 1
            }

            // Audit log
            if let storeId = user.storeId {
                let changeNote = actualQty != item.expectedQty
                    ? "Adjusted from \(item.expectedQty) → \(actualQty) (Δ \(actualQty - item.expectedQty))"
                    : "Count confirmed: \(actualQty) units"
                dataStore.logAudit(
                    storeId: storeId,
                    action: "Cycle Count — Stock Adjusted",
                    entityType: "Product",
                    entityId: item.product.id,
                    performedBy: user.id,
                    details: "SKU: \(item.product.sku) · \(changeNote)"
                )
            }

            // Move from pending → checked (use updated stock item so qty is live)
            pendingItems.removeAll { $0.id == item.id }
            checkedItems.insert(
                CycleCountItem(
                    id: item.id,
                    product: item.product,
                    stockItem: updated,
                    expectedQty: actualQty,    // expected is now the freshly-counted qty
                    lastChecked: .now
                ),
                at: 0
            )
            itemToCount = nil
            enteredCount = ""

        } catch {
            // silently fail for preview; in prod surface an alert
        }
    }
}

// MARK: - CycleCountItem

struct CycleCountItem: Identifiable {
    let id: UUID
    let product: Product
    let stockItem: StockItem
    let expectedQty: Int
    let lastChecked: Date?

    var daysOverdue: Int? {
        guard let date = lastChecked else { return nil }
        let days = Calendar.current.dateComponents([.day], from: date, to: .now).day ?? 0
        return days > 30 ? days : nil
    }
}
