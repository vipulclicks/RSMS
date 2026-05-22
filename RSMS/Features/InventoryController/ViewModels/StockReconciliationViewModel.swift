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

    // MARK: - Init

    init() {
        loadMockData()
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

    // MARK: - Mock Data

    private func loadMockData() {
        let watch = Product(
            id: UUID(), sku: "ML-WTC-8842",
            name: "Rose Gold Diamond Watch", category: "Watches",
            subcategory: "Ladies", brand: "Maison Lumière",
            collection: "Éternité", material: "18K Rose Gold",
            price: 24500, currency: "EUR", imageURL: nil,
            description: "Diamond-set bezel with mother-of-pearl dial.",
            isActive: true, createdAt: .now, updatedAt: .now
        )

        let bag = Product(
            id: UUID(), sku: "ML-BAG-5521",
            name: "Chevron Quilted Flap Bag", category: "Handbags",
            subcategory: "Shoulder Bags", brand: "Maison Lumière",
            collection: "Classique", material: "Lambskin",
            price: 6800, currency: "EUR", imageURL: nil,
            description: "Burgundy chevron quilted flap bag with gold chain.",
            isActive: true, createdAt: .now, updatedAt: .now
        )

        let necklace = Product(
            id: UUID(), sku: "ML-JWL-3310",
            name: "Pear Diamond Pendant Necklace", category: "Jewelry",
            subcategory: "Necklaces", brand: "Maison Lumière",
            collection: "Héritage", material: "18K Yellow Gold",
            price: 18200, currency: "EUR", imageURL: nil,
            description: "Pear-cut diamond pendant on tennis chain.",
            isActive: true, createdAt: .now, updatedAt: .now
        )

        let heels = Product(
            id: UUID(), sku: "ML-SHO-7714",
            name: "Chain Ankle Strap Stiletto", category: "Heels",
            subcategory: "Pumps", brand: "Maison Lumière",
            collection: "Parisienne", material: "Nappa Leather",
            price: 1150, currency: "EUR", imageURL: nil,
            description: "Nude stiletto with gold chain ankle strap.",
            isActive: true, createdAt: .now, updatedAt: .now
        )

        discrepancyItems = [
            DiscrepancyItem(
                id: UUID(), product: watch,
                expectedQty: 12, actualQty: 9, variance: -3,
                status: .pending,
                lastUpdated: Calendar.current.date(byAdding: .minute, value: -12, to: .now)!
            ),
            DiscrepancyItem(
                id: UUID(), product: bag,
                expectedQty: 8, actualQty: 6, variance: -2,
                status: .underReview,
                lastUpdated: Calendar.current.date(byAdding: .minute, value: -38, to: .now)!
            ),
            DiscrepancyItem(
                id: UUID(), product: necklace,
                expectedQty: 5, actualQty: 3, variance: -2,
                status: .pending,
                lastUpdated: Calendar.current.date(byAdding: .hour, value: -1, to: .now)!
            ),
            DiscrepancyItem(
                id: UUID(), product: heels,
                expectedQty: 15, actualQty: 15, variance: 0,
                status: .resolved,
                lastUpdated: Calendar.current.date(byAdding: .hour, value: -2, to: .now)!
            ),
        ]

        auditEntries = [
            ReconciliationAuditEntry(
                id: UUID(), userName: "Amélie Laurent",
                timestamp: Calendar.current.date(byAdding: .minute, value: -47, to: .now)!,
                productName: "Chain Ankle Strap Stiletto",
                previousQty: 13, updatedQty: 15,
                reason: .misplacedInventory
            ),
            ReconciliationAuditEntry(
                id: UUID(), userName: "Marc Dubois",
                timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: .now)!,
                productName: "Heritage Silk Scarf",
                previousQty: 22, updatedQty: 24,
                reason: .scanningError
            ),
            ReconciliationAuditEntry(
                id: UUID(), userName: "Sophie Chen",
                timestamp: Calendar.current.date(byAdding: .hour, value: -6, to: .now)!,
                productName: "Diamond Tennis Bracelet",
                previousQty: 7, updatedQty: 5,
                reason: .theftLoss
            ),
            ReconciliationAuditEntry(
                id: UUID(), userName: "Amélie Laurent",
                timestamp: Calendar.current.date(byAdding: .hour, value: -8, to: .now)!,
                productName: "Cashmere Wrap Coat",
                previousQty: 4, updatedQty: 3,
                reason: .supplierIssue
            ),
            ReconciliationAuditEntry(
                id: UUID(), userName: "Jean-Pierre Moreau",
                timestamp: Calendar.current.date(byAdding: .day, value: -2, to: .now)!,
                productName: "Monogram Leather Belt",
                previousQty: 18, updatedQty: 16,
                reason: .damagedItem
            ),
        ]
    }
}
