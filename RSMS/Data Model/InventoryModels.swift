//
//  InventoryModels.swift
//  RSMS_Mock_Data
//
//  Created by Prem Kumar on 18/05/26.
//

import Foundation

// MARK: - Product

/// The main record for a product. Every unique item variation (like color or size) has its own SKU here.
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

/// Keeps track of individual items in stock, often using RFID tags, and notes exactly where they are in the store.
struct StockItem: Codable, Identifiable, Hashable {
    let id: UUID
    let productId: UUID
    let storeId: UUID
    let quantity: Int
    let rfidTag: String?
    let location: String?           // e.g. "display_case_A3", "vault", "back_stock"
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
    case available   = "available"
    case reserved    = "reserved"
    case sold        = "sold"
    case inTransit   = "in_transit"
    case damaged     = "damaged"
    case onLoan      = "on_loan"
}

// MARK: - RFID Scan Record

/// Records what happens when someone does an RFID scan of the store, noting how many items were found and any issues.
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

// MARK: - Stock Discrepancy

/// Used to log when the number of items we actually have doesn't match what the system says we should have.
struct StockDiscrepancy: Codable, Identifiable, Hashable {
    let id: UUID
    let storeId: UUID
    let productId: UUID
    let expectedQty: Int
    let actualQty: Int
    let reportedBy: UUID
    let status: DiscrepancyStatus
    let resolution: String?
    let reportedAt: Date
    let resolvedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, status, resolution
        case storeId     = "store_id"
        case productId   = "product_id"
        case expectedQty = "expected_qty"
        case actualQty   = "actual_qty"
        case reportedBy  = "reported_by"
        case reportedAt  = "reported_at"
        case resolvedAt  = "resolved_at"
    }
}

enum DiscrepancyStatus: String, Codable, CaseIterable {
    case open         = "open"
    case investigating = "investigating"
    case resolved     = "resolved"
    case writeOff     = "write_off"
}

// MARK: - Stock Transfer

/// Represents a request to move inventory from one location to another, like from a warehouse to a store.
struct StockTransfer: Codable, Identifiable, Hashable {
    let id: UUID
    let fromStoreId: UUID
    let toStoreId: UUID
    let status: TransferStatus
    let requestedBy: UUID
    let approvedBy: UUID?
    let requestedAt: Date
    let shippedAt: Date?
    let receivedAt: Date?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, status, notes
        case fromStoreId  = "from_store_id"
        case toStoreId    = "to_store_id"
        case requestedBy  = "requested_by"
        case approvedBy   = "approved_by"
        case requestedAt  = "requested_at"
        case shippedAt    = "shipped_at"
        case receivedAt   = "received_at"
    }
}

enum TransferStatus: String, Codable, CaseIterable {
    case requested  = "requested"
    case approved   = "approved"
    case inTransit  = "in_transit"
    case received   = "received"
    case cancelled  = "cancelled"
}

/// Details the specific items and quantities being moved in a stock transfer.
struct TransferItem: Codable, Identifiable, Hashable {
    let id: UUID
    let transferId: UUID
    let productId: UUID
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case id, quantity
        case transferId = "transfer_id"
        case productId  = "product_id"
    }
}

// MARK: - Replenishment Shipment

/// Tracks a delivery coming from the main distribution center to a store, checking what was expected versus what arrived.
struct ReplenishmentShipment: Codable, Identifiable, Hashable {
    let id: UUID
    let storeId: UUID
    let dcId: String
    let asnNumber: String
    let expectedDate: Date
    let status: ShipmentStatus
    let receivedAt: Date?
    let receivedBy: UUID?
    let itemsExpected: Int
    let itemsReceived: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, status, notes
        case storeId       = "store_id"
        case dcId          = "dc_id"
        case asnNumber     = "asn_number"
        case expectedDate  = "expected_date"
        case receivedAt    = "received_at"
        case receivedBy    = "received_by"
        case itemsExpected = "items_expected"
        case itemsReceived = "items_received"
    }
}

enum ShipmentStatus: String, Codable, CaseIterable {
    case expected  = "expected"
    case inTransit = "in_transit"
    case received  = "received"
    case partial   = "partial"
    case exception = "exception"
}

// MARK: - Vendor Return

/// Used when the store needs to send items back to the supplier, whether they are damaged or just overstocked.
struct VendorReturn: Codable, Identifiable, Hashable {
    let id: UUID
    let storeId: UUID
    let vendorId: String
    let vendorName: String
    let reason: String
    let status: VendorReturnStatus
    let createdBy: UUID
    let createdAt: Date
    let shippedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, reason, status
        case storeId    = "store_id"
        case vendorId   = "vendor_id"
        case vendorName = "vendor_name"
        case createdBy  = "created_by"
        case createdAt  = "created_at"
        case shippedAt  = "shipped_at"
    }
}

enum VendorReturnStatus: String, Codable, CaseIterable {
    case pending   = "pending"
    case approved  = "approved"
    case shipped   = "shipped"
    case completed = "completed"
}

/// Lists the specific items being sent back to the vendor.
struct VendorReturnItem: Codable, Identifiable, Hashable {
    let id: UUID
    let vendorReturnId: UUID
    let productId: UUID
    let quantity: Int
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case id, quantity, reason
        case vendorReturnId = "vendor_return_id"
        case productId      = "product_id"
    }
}

// MARK: - Cycle Count

/// Records an inventory counting session, whether it's a regular check or just a spontaneous count.
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

/// Shows the results of a count for a specific item, highlighting any differences between the physical count and the system.
struct CycleCountItem: Codable, Identifiable, Hashable {
    let id: UUID
    let cycleCountId: UUID
    let productId: UUID
    let systemQty: Int
    let countedQty: Int
    let variance: Int

    enum CodingKeys: String, CodingKey {
        case id, variance
        case cycleCountId = "cycle_count_id"
        case productId    = "product_id"
        case systemQty    = "system_qty"
        case countedQty   = "counted_qty"
    }
}

// MARK: - Audit Trail

/// A permanent record of an action taken in the inventory system, keeping an audit trail of who did what and when.
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

/// Stores the unique serial number scanned for a specific item.
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

/// Represents a certificate proving an item is authentic, tied directly to its serial number.
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

// MARK: - Shrinkage Analytics

/// Provides a summary of how much inventory was lost or stolen over a certain time, showing the total impact.
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
