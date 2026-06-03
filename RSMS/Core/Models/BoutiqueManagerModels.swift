//
//  BoutiqueManagerModels.swift
//  RSMS
//
//  RSMS_Mock_Data
//

import Foundation
import SwiftUI

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

    /// Date-only formatter used for the Postgres `date` column.
    /// Using the local calendar so that "2026-05-31" always means
    /// May 31 in the device's timezone, not midnight UTC.
    private static let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current          // ← local timezone, NOT UTC
        return f
    }()

    // Custom decoder: read shift_date as a plain "yyyy-MM-dd" string
    // and interpret it in the device's local timezone so that
    // Calendar.current.isDateInToday() works correctly.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decode(UUID.self, forKey: .id)
        staffId   = try c.decode(UUID.self, forKey: .staffId)
        storeId   = try c.decode(UUID.self, forKey: .storeId)
        startTime = try c.decode(String.self, forKey: .startTime)
        endTime   = try c.decode(String.self, forKey: .endTime)
        role      = try c.decode(String.self, forKey: .role)
        notes     = try c.decodeIfPresent(String.self, forKey: .notes)

        let dateStr = try c.decode(String.self, forKey: .shiftDate)
        guard let d = Self.dateOnlyFormatter.date(from: dateStr) else {
            throw DecodingError.dataCorruptedError(
                forKey: .shiftDate, in: c,
                debugDescription: "Cannot decode shift_date: \(dateStr)"
            )
        }
        shiftDate = d
    }

    // Custom encoder: write shift_date as "yyyy-MM-dd" so that it
    // matches the Postgres `date` column format.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(staffId, forKey: .staffId)
        try c.encode(storeId, forKey: .storeId)
        try c.encode(Self.dateOnlyFormatter.string(from: shiftDate), forKey: .shiftDate)
        try c.encode(startTime, forKey: .startTime)
        try c.encode(endTime, forKey: .endTime)
        try c.encode(role, forKey: .role)
        try c.encode(notes, forKey: .notes)
    }

    // Keep the memberwise init for creating shifts in code
    init(id: UUID, staffId: UUID, storeId: UUID, shiftDate: Date,
         startTime: String, endTime: String, role: String, notes: String?) {
        self.id = id
        self.staffId = staffId
        self.storeId = storeId
        self.shiftDate = shiftDate
        self.startTime = startTime
        self.endTime = endTime
        self.role = role
        self.notes = notes
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

    private static let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        return f
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        staffId = try c.decode(UUID.self, forKey: .staffId)
        storeId = try c.decode(UUID.self, forKey: .storeId)
        targetAmount = try c.decode(Double.self, forKey: .targetAmount)
        achievedAmount = try c.decode(Double.self, forKey: .achievedAmount)
        period = try c.decode(GoalPeriod.self, forKey: .period)

        let startStr = try c.decode(String.self, forKey: .startDate)
        guard let sd = Self.dateOnlyFormatter.date(from: startStr) else {
            throw DecodingError.dataCorruptedError(forKey: .startDate, in: c, debugDescription: "Cannot decode start_date")
        }
        startDate = sd

        let endStr = try c.decode(String.self, forKey: .endDate)
        guard let ed = Self.dateOnlyFormatter.date(from: endStr) else {
            throw DecodingError.dataCorruptedError(forKey: .endDate, in: c, debugDescription: "Cannot decode end_date")
        }
        endDate = ed

        // createdAt comes as ISO8601 from Supabase
        let createdStr = try c.decode(String.self, forKey: .createdAt)
        if let cd = Self.isoFormatter.date(from: createdStr) {
            createdAt = cd
        } else {
            // Fallback without fractional seconds
            let fallbackFormatter = ISO8601DateFormatter()
            fallbackFormatter.formatOptions = [.withInternetDateTime]
            if let cd = fallbackFormatter.date(from: createdStr) {
                createdAt = cd
            } else {
                throw DecodingError.dataCorruptedError(forKey: .createdAt, in: c, debugDescription: "Cannot decode created_at")
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(staffId, forKey: .staffId)
        try c.encode(storeId, forKey: .storeId)
        try c.encode(targetAmount, forKey: .targetAmount)
        try c.encode(achievedAmount, forKey: .achievedAmount)
        try c.encode(period, forKey: .period)
        try c.encode(Self.dateOnlyFormatter.string(from: startDate), forKey: .startDate)
        try c.encode(Self.dateOnlyFormatter.string(from: endDate), forKey: .endDate)
        try c.encode(Self.isoFormatter.string(from: createdAt), forKey: .createdAt)
    }

    init(id: UUID, staffId: UUID, storeId: UUID, targetAmount: Double, achievedAmount: Double, period: GoalPeriod, startDate: Date, endDate: Date, createdAt: Date) {
        self.id = id
        self.staffId = staffId
        self.storeId = storeId
        self.targetAmount = targetAmount
        self.achievedAmount = achievedAmount
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
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

/// A digital lookbook document stored as a PDF.
struct Lookbook: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let isActive: Bool
    let createdAt: Date
    let pdfStoragePath: String?

    enum CodingKeys: String, CodingKey {
        case id, title
        case isActive       = "is_active"
        case createdAt      = "created_at"
        case pdfStoragePath = "pdf_storage_path"
    }
}

// MARK: - Compliance Check

/// Records the results of checking whether a store's display matches the required planogram.
struct ComplianceCheck: Codable, Identifiable, Hashable {
    var id: UUID
    var storeId: UUID
    var planogramId: UUID
    var checkedBy: UUID
    var status: ComplianceStatus
    var notes: String?
    var photoURLs: [String]?
    var checkedAt: Date

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
    
    var displayName: String {
        switch self {
        case .compliant: return "Compliant"
        case .nonCompliant: return "Non-Compliant"
        case .needsReview: return "Needs Review"
        }
    }
    
    var color: SwiftUI.Color {
        switch self {
        case .compliant: return RSMSTheme.info
        case .nonCompliant: return RSMSTheme.danger
        case .needsReview: return RSMSTheme.warning
        }
    }
    
    var iconName: String {
        switch self {
        case .compliant: return "checkmark.circle.fill"
        case .nonCompliant: return "xmark.octagon.fill"
        case .needsReview: return "exclamationmark.triangle.fill"
        }
    }
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
    case pending   = "pending"
    case confirmed = "confirmed"
    case declined  = "declined"
    case attended  = "attended"
    case noShow    = "no_show"

    var displayName: String {
        switch self {
        case .invited: return "Pending"
        case .confirmed: return "Accepted"
        case .declined: return "Declined"
        case .attended: return "Attended"
        case .noShow: return "No Show"
        }
    }

    var color: SwiftUI.Color {
        switch self {
        case .invited: return RSMSTheme.warning
        case .confirmed, .attended: return RSMSTheme.success
        case .declined, .noShow: return RSMSTheme.danger
        }
    }
}

