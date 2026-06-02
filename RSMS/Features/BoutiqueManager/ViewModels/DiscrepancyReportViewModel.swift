//
//  DiscrepancyReportViewModel.swift
//  RSMS
//
//  ViewModel for the Boutique Manager's stock discrepancy reporting flow.
//  Uses existing DataStore methods — no backend changes required.
//

import SwiftUI

@Observable
final class DiscrepancyReportViewModel {

    // MARK: - State

    var isLoading = false
    var isSaving = false
    var errorMessage: String?
    var didSubmitSuccessfully = false

    // Form fields
    var searchText = ""
    var selectedProduct: Product?
    var expectedQty: String = ""
    var actualQty: String = ""
    var issueType: IssueType = .missing
    var notes: String = ""

    // Products list (cached from DataStore)
    var allProducts: [Product] = []

    // Submitted reports (local cache for the session)
    var submittedReports: [InventoryVariance] = []

    // MARK: - Issue Type

    enum IssueType: String, CaseIterable, Identifiable {
        case missing  = "Missing Stock"
        case excess   = "Excess Stock"
        case damaged  = "Damaged"
        case other    = "Other"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .missing:  return "minus.circle.fill"
            case .excess:   return "plus.circle.fill"
            case .damaged:  return "exclamationmark.triangle.fill"
            case .other:    return "questionmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .missing:  return RSMSTheme.danger
            case .excess:   return RSMSTheme.warning
            case .damaged:  return Color.orange
            case .other:    return RSMSTheme.textSecondary
            }
        }
    }

    // MARK: - Computed

    var filteredProducts: [Product] {
        guard !searchText.isEmpty else { return allProducts }
        let query = searchText.lowercased()
        return allProducts.filter {
            $0.name.lowercased().contains(query) ||
            $0.sku.lowercased().contains(query) ||
            $0.category.lowercased().contains(query)
        }
    }

    var computedVariance: Int? {
        guard let expected = Int(expectedQty), let actual = Int(actualQty) else { return nil }
        return actual - expected
    }

    var canSubmit: Bool {
        selectedProduct != nil &&
        !expectedQty.isEmpty &&
        !actualQty.isEmpty &&
        Int(expectedQty) != nil &&
        Int(actualQty) != nil &&
        Int(expectedQty) != Int(actualQty) &&
        !isSaving
    }

    // MARK: - Load

    @MainActor
    func load(dataStore: DataStore, storeId: UUID?) async {
        isLoading = true
        defer { isLoading = false }

        if dataStore.products.isEmpty {
            try? await dataStore.fetchProducts()
        }
        allProducts = dataStore.products.filter { $0.isActive }

        // Load existing variances for this store
        if let sid = storeId {
            try? await dataStore.fetchInventoryVariances(storeId: sid)
            submittedReports = dataStore.inventoryVariances
                .sorted { $0.reportedAt > $1.reportedAt }
        }
    }

    // MARK: - Select Product

    func selectProduct(_ product: Product, dataStore: DataStore) {
        selectedProduct = product
        searchText = product.name

        // Auto-fill expected quantity from stock
        if let stock = dataStore.stockItems.first(where: { $0.productId == product.id }) {
            expectedQty = "\(stock.quantity)"
        } else {
            expectedQty = "0"
        }

        // Clear actual qty for user input
        actualQty = ""
    }

    // MARK: - Submit

    @MainActor
    func submitReport(dataStore: DataStore, user: UserProfile) async {
        guard let product = selectedProduct,
              let expected = Int(expectedQty),
              let actual = Int(actualQty),
              let storeId = user.storeId else { return }

        isSaving = true
        errorMessage = nil
        didSubmitSuccessfully = false

        do {
            let variance = InventoryVariance(
                id: UUID(),
                storeId: storeId,
                productId: product.id,
                expectedQty: expected,
                actualQty: actual,
                variance: actual - expected,
                reportedBy: user.id,
                status: .open,
                cycleCountId: nil,
                resolution: notes.isEmpty ? nil : "[\(issueType.rawValue)] \(notes)",
                reportedAt: .now,
                resolvedAt: nil
            )

            try await dataStore.createInventoryVariance(variance)

            // Audit trail
            dataStore.logAudit(
                storeId: storeId,
                action: "Discrepancy Report",
                entityType: "InventoryVariance",
                entityId: variance.id,
                performedBy: user.id,
                details: "SKU: \(product.sku) · Type: \(issueType.rawValue) · Expected: \(expected) · Actual: \(actual) · Variance: \(actual - expected)"
            )

            // Update local list
            submittedReports.insert(variance, at: 0)

            // Reset form
            didSubmitSuccessfully = true
            resetForm()

        } catch {
            errorMessage = "Failed to submit: \(error.localizedDescription)"
        }

        isSaving = false
    }

    // MARK: - Reset

    func resetForm() {
        selectedProduct = nil
        searchText = ""
        expectedQty = ""
        actualQty = ""
        issueType = .missing
        notes = ""
    }

    // MARK: - Helpers

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func productName(for productId: UUID) -> String {
        allProducts.first(where: { $0.id == productId })?.name ?? "Unknown"
    }

    func productSKU(for productId: UUID) -> String {
        allProducts.first(where: { $0.id == productId })?.sku ?? "—"
    }
}
