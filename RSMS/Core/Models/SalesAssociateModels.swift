//
//  SalesAssociateModels.swift
//  RSMS
//
//  RSMS_Mock_Data
//

import Foundation

// MARK: - Client Profile

/// A luxury retail client (customer) with preferences and consent tracking.
struct ClientProfile: Codable, Identifiable, Hashable {
    let id: UUID
    let fullName: String
    let email: String?
    let phone: String?
    let preferredStoreId: UUID?
    let vipTier: VIPTier
    let privacyConsentGiven: Bool
    let consentDate: Date?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, email, phone, notes
        case fullName            = "full_name"
        case preferredStoreId    = "preferred_store_id"
        case vipTier             = "vip_tier"
        case privacyConsentGiven = "privacy_consent_given"
        case consentDate         = "consent_date"
        case createdAt           = "created_at"
        case updatedAt           = "updated_at"
    }
}

enum VIPTier: String, Codable, CaseIterable {
    case standard = "standard"
    case silver   = "silver"
    case gold     = "gold"
    case platinum = "platinum"
    case prive    = "prive"
}

// MARK: - Client Preference

/// Stored size, category, and styling preferences for a client.
struct ClientPreference: Codable, Identifiable, Hashable {
    let id: UUID
    let clientId: UUID
    let ringSize: String?
    let braceletSize: String?
    let necklaceLength: String?
    let wristSize: String?
    let favoriteCategories: [String]
    let favoriteMetals: [String]?
    let favoriteGemstones: [String]?
    let notes: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, notes
        case clientId           = "client_id"
        case ringSize           = "ring_size"
        case braceletSize       = "bracelet_size"
        case necklaceLength     = "necklace_length"
        case wristSize          = "wrist_size"
        case favoriteCategories = "favorite_categories"
        case favoriteMetals     = "favorite_metals"
        case favoriteGemstones  = "favorite_gemstones"
        case updatedAt          = "updated_at"
    }
}

// MARK: - Client Anniversary

/// Important dates for a client (birthday, wedding, etc.) used for personalized engagement.
struct ClientAnniversary: Codable, Identifiable, Hashable {
    let id: UUID
    let clientId: UUID
    let title: String
    let date: Date
    let reminderEnabled: Bool
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, title, date, notes
        case clientId        = "client_id"
        case reminderEnabled = "reminder_enabled"
    }
}

// MARK: - Wishlist Item

/// A product on a client's wishlist, managed by the sales associate.
struct WishlistItem: Codable, Identifiable, Hashable {
    let id: UUID
    let clientId: UUID
    let productId: UUID
    let addedAt: Date
    let isAvailable: Bool
    let notifyOnRestock: Bool
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, notes
        case clientId       = "client_id"
        case productId      = "product_id"
        case addedAt        = "added_at"
        case isAvailable    = "is_available"
        case notifyOnRestock = "notify_on_restock"
    }
}

// MARK: - Appointment

/// A scheduled client appointment (in-store or video consultation).
struct Appointment: Codable, Identifiable, Hashable {
    let id: UUID
    let clientId: UUID
    let associateId: UUID
    let storeId: UUID
    let dateTime: Date
    let durationMinutes: Int
    let type: AppointmentType
    let status: AppointmentStatus
    let reminderSentAt: Date?
    let videoLink: String?
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, type, status, notes
        case clientId        = "client_id"
        case associateId     = "associate_id"
        case storeId         = "store_id"
        case dateTime        = "date_time"
        case durationMinutes = "duration_minutes"
        case reminderSentAt  = "reminder_sent_at"
        case videoLink       = "video_link"
        case createdAt       = "created_at"
    }
}

enum AppointmentType: String, Codable, CaseIterable {
    case inStore = "in_store"
    case video   = "video"
    case phone   = "phone"
}

enum AppointmentStatus: String, Codable, CaseIterable {
    case scheduled  = "scheduled"
    case confirmed  = "confirmed"
    case inProgress = "in_progress"
    case completed  = "completed"
    case cancelled  = "cancelled"
    case noShow     = "no_show"
}

// MARK: - Curated Cart

/// A personalized cart prepared by a sales associate for a specific client.
struct CuratedCart: Codable, Identifiable, Hashable {
    let id: UUID
    let clientId: UUID
    let associateId: UUID
    let note: String?
    let status: CuratedCartStatus
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, note, status
        case clientId    = "client_id"
        case associateId = "associate_id"
        case createdAt   = "created_at"
        case updatedAt   = "updated_at"
    }
}

enum CuratedCartStatus: String, Codable, CaseIterable {
    case draft     = "draft"
    case shared    = "shared"
    case viewed    = "viewed"
    case converted = "converted"
    case expired   = "expired"
}

/// A line item within a curated cart.
struct CuratedCartItem: Codable, Identifiable, Hashable {
    let id: UUID
    let cartId: UUID
    let productId: UUID
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id, note
        case cartId   = "cart_id"
        case productId = "product_id"
    }
}

// MARK: - AI Recommendation

/// An AI-generated product recommendation for a client.
struct AIRecommendation: Codable, Identifiable, Hashable {
    let id: UUID
    let clientId: UUID
    let productId: UUID
    let type: RecommendationType
    let confidence: Double
    let reason: String?
    let isAccepted: Bool?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, type, confidence, reason
        case clientId   = "client_id"
        case productId  = "product_id"
        case isAccepted = "is_accepted"
        case createdAt  = "created_at"
    }
}

enum RecommendationType: String, Codable, CaseIterable {
    case crossSell = "cross_sell"
    case upSell    = "up_sell"
    case similar   = "similar"
    case trending  = "trending"
}

// MARK: - Look Builder Outfit

/// A styled outfit / product combination created by a sales associate.
struct LookBuilderOutfit: Codable, Identifiable, Hashable {
    let id: UUID
    let associateId: UUID
    let clientId: UUID?
    let name: String
    let productIds: [UUID]
    let imageURL: String?
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, notes
        case associateId = "associate_id"
        case clientId    = "client_id"
        case productIds  = "product_ids"
        case imageURL    = "image_url"
        case createdAt   = "created_at"
    }
}
