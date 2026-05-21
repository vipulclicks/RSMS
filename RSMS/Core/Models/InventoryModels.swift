//
//  InventoryModels.swift
//  RSMS
//
//  Inventory, RFID, movements, cycle counts, auditing, serialization, and shrinkage
//  — aligned with Supabase public schema.
//

import Foundation

// MARK: - Product

/// The master product record. Every unique item variation has its own SKU.
/// Maps to Supabase `products` table.
struct Product: Codable, Identifiable, Hashable {
    let id: UUID
    let sku: String
    let name: String
    let category: String
    let subcategory: String?
    let brand: String
    let collection: String?
    let material: String?
    let price: Double
    let currency: String
    let imageURL: String?
    let description: String?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, sku, name, category, subcategory, brand, collection, material
        case price, currency, description
        case imageURL  = "image_url"
        case isActive  = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Stock Item

/// An inventory record for a product at a specific store, optionally RFID-tagged.
/// Maps to Supabase `stock_items` table.
struct StockItem: Codable, Identifiable, Hashable {
    let id: UUID
    let productId: UUID
    let storeId: UUID
    let quantity: Int
    let rfidTag: String?
    let location: String?
    let status: StockStatus
    let lastScannedAt: Date?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, quantity, location, status
        case productId     = "product_id"
        case storeId       = "store_id"
        case rfidTag       = "rfid_tag"
        case lastScannedAt = "last_scanned_at"
        case updatedAt     = "updated_at"
    }
}

enum StockStatus: String, Codable, CaseIterable {
    case available = "available"
    case reserved  = "reserved"
    case sold      = "sold"
    case inTransit = "in_transit"
    case damaged   = "damaged"
    case onLoan    = "on_loan"
}

// MARK: - RFID Scan Record

/// A record of an RFID scan session in a store.
/// Maps to Supabase `rfid_scan_records` table.
struct RFIDScanRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let storeId: UUID
    let scannedBy: UUID
    let scannedAt: Date
    let itemsScanned: Int
    let exceptionsFound: Int
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, notes
        case storeId         = "store_id"
        case scannedBy       = "scanned_by"
        case scannedAt       = "scanned_at"
        case itemsScanned    = "items_scanned"
        case exceptionsFound = "exceptions_found"
    }
}

// MARK: - Inventory Variance

/// Logs when physical stock count differs from system records.
/// Maps to Supabase `inventory_variances` table.
struct InventoryVariance: Codable, Identifiable, Hashable {
    let id: UUID
    let storeId: UUID
    let productId: UUID
    let expectedQty: Int
    let actualQty: Int
    let variance: Int
    let reportedBy: UUID
    let status: VarianceStatus
    let cycleCountId: UUID?
    let resolution: String?
    let reportedAt: Date
    let resolvedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, variance, status, resolution
        case storeId      = "store_id"
        case productId    = "product_id"
        case expectedQty  = "expected_qty"
        case actualQty    = "actual_qty"
        case reportedBy   = "reported_by"
        case cycleCountId = "cycle_count_id"
        case reportedAt   = "reported_at"
        case resolvedAt   = "resolved_at"
    }
}

enum VarianceStatus: String, Codable, CaseIterable {
    case open          = "open"
    case investigating = "investigating"
    case resolved      = "resolved"
    case writeOff      = "write_off"
}

// MARK: - Inventory Movement

/// Unified model for store transfers, DC replenishments, and vendor returns.
/// Maps to Supabase `inventory_movements` table.
/// The `type` field distinguishes the movement kind.
struct InventoryMovement: Codable, Identifiable, Hashable {
    let id: UUID
    let type: MovementType
    let sourceId: String
    let destinationId: String
    let status: MovementStatus
    let requestedBy: UUID?
    let approvedBy: UUID?
    let requestedAt: Date?
    let shippedAt: Date?
    let receivedAt: Date?
    let asnNumber: String?
    let itemsExpected: Int?
    let itemsReceived: Int?
    let reason: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, type, status, reason, notes
        case sourceId      = "source_id"
        case destinationId = "destination_id"
        case requestedBy   = "requested_by"
        case approvedBy    = "approved_by"
        case requestedAt   = "requested_at"
        case shippedAt     = "shipped_at"
        case receivedAt    = "received_at"
        case asnNumber     = "asn_number"
        case itemsExpected = "items_expected"
        case itemsReceived = "items_received"
    }
}

enum MovementType: String, Codable, CaseIterable {
    case storeTransfer    = "store_transfer"
    case dcReplenishment  = "dc_replenishment"
    case vendorReturn     = "vendor_return"
}

enum MovementStatus: String, Codable, CaseIterable {
    case requested  = "requested"
    case approved   = "approved"
    case inTransit  = "in_transit"
    case received   = "received"
    case completed  = "completed"
    case cancelled  = "cancelled"
    case partial    = "partial"
    case exception  = "exception"
}

// MARK: - Movement Item

/// A line item within an inventory movement.
/// Maps to Supabase `movement_items` table.
struct MovementItem: Codable, Identifiable, Hashable {
    let id: UUID
    let movementId: UUID
    let productId: UUID
    let quantity: Int
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case id, quantity, reason
        case movementId = "movement_id"
        case productId  = "product_id"
    }
}

// MARK: - Cycle Count

/// A scheduled or ad-hoc inventory counting session.
/// Maps to Supabase `cycle_counts` table.
struct CycleCount: Codable, Identifiable, Hashable {
    let id: UUID
    let storeId: UUID
    let scheduledDate: Date
    let status: CycleCountStatus
    let conductedBy: UUID?
    let completedAt: Date?
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, status, notes
        case storeId       = "store_id"
        case scheduledDate = "scheduled_date"
        case conductedBy   = "conducted_by"
        case completedAt   = "completed_at"
        case createdAt     = "created_at"
    }
}

enum CycleCountStatus: String, Codable, CaseIterable {
    case scheduled  = "scheduled"
    case inProgress = "in_progress"
    case completed  = "completed"
    case cancelled  = "cancelled"
}

// MARK: - Audit Trail

/// An immutable record of an action in the system.
/// Maps to Supabase `audit_trails` table.
struct AuditTrail: Codable, Identifiable, Hashable {
    let id: UUID
    let storeId: UUID
    let action: String
    let entityType: String
    let entityId: UUID
    let performedBy: UUID
    let timestamp: Date
    let details: String?

    enum CodingKeys: String, CodingKey {
        case id, action, timestamp, details
        case storeId     = "store_id"
        case entityType  = "entity_type"
        case entityId    = "entity_id"
        case performedBy = "performed_by"
    }
}

// MARK: - Serial Capture

/// A serial number captured for a specific product.
/// Maps to Supabase `serial_captures` table.
struct SerialCapture: Codable, Identifiable, Hashable {
    let id: UUID
    let productId: UUID
    let serialNumber: String
    let capturedBy: UUID
    let capturedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case productId    = "product_id"
        case serialNumber = "serial_number"
        case capturedBy   = "captured_by"
        case capturedAt   = "captured_at"
    }
}

// MARK: - Authenticity Certificate

/// A certificate proving an item's authenticity, tied to its serial number.
/// Maps to Supabase `auth_certificates` table.
struct AuthCertificate: Codable, Identifiable, Hashable {
    let id: UUID
    let productId: UUID
    let serialNumber: String
    let certificateURL: String?
    let issuedAt: Date
    let issuedBy: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case productId      = "product_id"
        case serialNumber   = "serial_number"
        case certificateURL = "certificate_url"
        case issuedAt       = "issued_at"
        case issuedBy       = "issued_by"
    }
}

// MARK: - Dashboard Snapshot

/// Aggregates all KPIs shown on the Inventory Controller home dashboard into one model.
/// Swap the `preview` static for a real data source when a backend is connected.
struct InventoryDashboardSnapshot {
    let totalInventoryCount: Int
    let todaysScanCount: Int
    let scanCompletionPercent: Double   // 0.0 – 1.0
    let lowStockAlertCount: Int
    let newLowStockCount: Int           // value shown in "+N New" badge
    let pendingTaskCount: Int
    let recentActivity: [AuditTrail]
}

// MARK: - Inventory Variance

enum VarianceStatus: String, Codable {
    case open, investigating, resolved, closed
}

struct InventoryVariance: Codable, Identifiable, Hashable {
    let id: UUID
    let storeId: UUID
    let productId: UUID
    let reportedQuantity: Int
    let expectedQuantity: Int
    let status: VarianceStatus
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, status
        case storeId          = "store_id"
        case productId        = "product_id"
        case reportedQuantity = "reported_quantity"
        case expectedQuantity = "expected_quantity"
        case createdAt        = "created_at"
    }
    
    static let preview = InventoryVariance(
        id: UUID(),
        storeId: UUID(),
        productId: UUID(),
        reportedQuantity: 40,
        expectedQuantity: 42,
        status: .open,
        createdAt: .now
    )
}

// MARK: - Shrinkage Analytics

/// A summary of inventory loss over a period.
/// Maps to Supabase `shrinkage_analytics` table.
struct ShrinkageAnalytics: Codable, Identifiable, Hashable {
    let id: UUID
    let storeId: UUID
    let periodStart: Date
    let periodEnd: Date
    let totalLossUnits: Int
    let totalLossValue: Double
    let currency: String
    let topCategory: String?
    let primaryCause: String?

    enum CodingKeys: String, CodingKey {
        case id, currency
        case storeId        = "store_id"
        case periodStart    = "period_start"
        case periodEnd      = "period_end"
        case totalLossUnits = "total_loss_units"
        case totalLossValue = "total_loss_value"
        case topCategory    = "top_category"
        case primaryCause   = "primary_cause"
    }
}

// MARK: - Scan Mode

/// Describes the intent of a barcode scanning session.
/// Drives stock updates, audit log wording, and UI badge colours.
enum ScanMode: String, CaseIterable, Identifiable {
    case stockIn      = "Stock In"
    case verification = "Verify"
    case audit        = "Audit"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .stockIn:      return "plus.circle.fill"
        case .verification: return "checkmark.circle.fill"
        case .audit:        return "doc.text.magnifyingglass"
        }
    }

    /// Audit trail action string written to Supabase.
    var auditAction: String {
        switch self {
        case .stockIn:      return "Stock In — Barcode Scan"
        case .verification: return "Verification — Barcode Scan"
        case .audit:        return "Audit — Barcode Scan"
        }
    }
}

// MARK: - Scan Log Entry

/// A single confirmed scan recorded in the in-session history log.
/// Shown in the Session Log panel of the scanner view.
struct ScanLogEntry: Identifiable {
    let id: UUID
    let sku: String
    let productName: String
    let timestamp: Date
    let mode: ScanMode
    let success: Bool
}
