//
//  BoutiqueManagerModels.swift
//  RSMS
//
//  RSMS_Mock_Data
//

import Foundation

// MARK: - Dashboard Summary

/// This model holds a daily snapshot of store performance, giving the boutique manager a quick overview of sales, appointments, and footfall.
struct DashboardSummary: Codable, Identifiable, Hashable {
    let id: UUID
    let storeId: UUID
    let date: Date
    let salesTarget: Double
    let salesActual: Double
    let appointmentCount: Int
    let lowStockAlertCount: Int
    let topSellingCategory: String?
    let footfallCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, date
        case storeId             = "store_id"
        case salesTarget         = "sales_target"
        case salesActual         = "sales_actual"
        case appointmentCount    = "appointment_count"
        case lowStockAlertCount  = "low_stock_alert_count"
        case topSellingCategory  = "top_selling_category"
        case footfallCount       = "footfall_count"
    }
}

// MARK: - Staff Shift

/// Represents a scheduled work shift for a staff member, including their role and hours for the day.
struct StaffShift: Codable, Identifiable, Hashable {
    let id: UUID
    let staffId: UUID
    let storeId: UUID
    let shiftDate: Date
    let startTime: String       // HH:mm format
    let endTime: String         // HH:mm format
    let role: String            // e.g. "floor", "cashier", "back_office"
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, role, notes
        case staffId   = "staff_id"
        case storeId   = "store_id"
        case shiftDate = "shift_date"
        case startTime = "start_time"
        case endTime   = "end_time"
    }
}

// MARK: - Sales Goal

/// Keeps track of the sales targets set by the manager for individual staff members.
struct SalesGoal: Codable, Identifiable, Hashable {
    let id: UUID
    let staffId: UUID
    let storeId: UUID
    let targetAmount: Double
    let achievedAmount: Double
    let period: GoalPeriod
    let startDate: Date
    let endDate: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, period
        case staffId        = "staff_id"
        case storeId        = "store_id"
        case targetAmount   = "target_amount"
        case achievedAmount = "achieved_amount"
        case startDate      = "start_date"
        case endDate        = "end_date"
        case createdAt      = "created_at"
    }
}

enum GoalPeriod: String, Codable, CaseIterable {
    case daily   = "daily"
    case weekly  = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
}

// MARK: - Commission

/// Represents the commission earned by a staff member on a specific sale.
struct Commission: Codable, Identifiable, Hashable {
    let id: UUID
    let staffId: UUID
    let transactionId: UUID
    let amount: Double
    let rate: Double            // e.g. 0.05 = 5%
    let status: CommissionStatus
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, amount, rate, status
        case staffId       = "staff_id"
        case transactionId = "transaction_id"
        case createdAt     = "created_at"
    }
}

enum CommissionStatus: String, Codable, CaseIterable {
    case pending  = "pending"
    case approved = "approved"
    case paid     = "paid"
}

// MARK: - Performance Metric

/// A summary of how a staff member is performing over a specific period, like their total sales and conversion rates.
struct PerformanceMetric: Codable, Identifiable, Hashable {
    let id: UUID
    let staffId: UUID
    let storeId: UUID
    let totalSales: Double
    let unitsSold: Int
    let avgTransactionValue: Double
    let conversionRate: Double?
    let period: GoalPeriod
    let periodStart: Date
    let periodEnd: Date

    enum CodingKeys: String, CodingKey {
        case id, period
        case staffId             = "staff_id"
        case storeId             = "store_id"
        case totalSales          = "total_sales"
        case unitsSold           = "units_sold"
        case avgTransactionValue = "avg_transaction_value"
        case conversionRate      = "conversion_rate"
        case periodStart         = "period_start"
        case periodEnd           = "period_end"
    }
}



// MARK: - Lookbook

/// A published lookbook document stored in Supabase.
struct Lookbook: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let isActive: Bool
    let createdAt: Date
    let pdfStoragePath: String?

    enum CodingKeys: String, CodingKey {
        case id, title
        case isActive        = "is_active"
        case createdAt       = "created_at"
        case pdfStoragePath  = "pdf_storage_path"
    }

    static let preview = Lookbook(
        id: UUID(uuidString: "30000000-0000-0000-0000-0000000000C0")!,
        title: "Maison Lumiere Summer 2026",
        isActive: true,
        createdAt: .now,
        pdfStoragePath: "lookbooks/summer-2026.pdf"
    )
}

// MARK: - Compliance Check

/// Records the results of checking whether a store's display matches the required planogram.
struct ComplianceCheck: Codable, Identifiable, Hashable {
    let id: UUID
    let storeId: UUID
    let planogramId: UUID
    let checkedBy: UUID
    let status: ComplianceStatus
    let notes: String?
    let photoURLs: [String]?
    let checkedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, status, notes
        case storeId     = "store_id"
        case planogramId = "planogram_id"
        case checkedBy   = "checked_by"
        case photoURLs   = "photo_urls"
        case checkedAt   = "checked_at"
    }
}

enum ComplianceStatus: String, Codable, CaseIterable {
    case compliant    = "compliant"
    case nonCompliant = "non_compliant"
    case needsReview  = "needs_review"
}

// MARK: - Client Event

/// Keeps track of special events for clients, like VIP previews or trunk shows.
struct ClientEvent: Codable, Identifiable, Hashable {
    let id: UUID
    let storeId: UUID
    let title: String
    let description: String?
    let type: ClientEventType
    let date: Date
    let endDate: Date?
    let capacity: Int
    let location: String?
    let createdBy: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, description, type, date, capacity, location
        case storeId   = "store_id"
        case endDate   = "end_date"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

enum ClientEventType: String, Codable, CaseIterable {
    case trunkShow  = "trunk_show"
    case vipPreview = "vip_preview"
    case launch     = "launch"
    case privateViewing = "private_viewing"
}

// MARK: - Event Invitation

/// Manages who was invited to an event and whether they are planning to attend.
struct EventInvitation: Codable, Identifiable, Hashable {
    let id: UUID
    let eventId: UUID
    let clientId: UUID
    let status: RSVPStatus
    let sentAt: Date
    let respondedAt: Date?
    let plusOne: Bool

    enum CodingKeys: String, CodingKey {
        case id, status
        case eventId     = "event_id"
        case clientId    = "client_id"
        case sentAt      = "sent_at"
        case respondedAt = "responded_at"
        case plusOne      = "plus_one"
    }
}

enum RSVPStatus: String, Codable, CaseIterable {
    case invited   = "invited"
    case confirmed = "confirmed"
    case declined  = "declined"
    case attended  = "attended"
    case noShow    = "no_show"
}

