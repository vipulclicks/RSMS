//
//  SalesAssociateModels.swift
//  RSMS
//
//  Models for clienteling, appointments, wishlists, AI recommendations,
//  and look builder — aligned with Supabase public schema.
//

import Foundation

// MARK: - Client Profile

/// A luxury retail client with preferences, sizes, and consent tracking.
/// Maps to Supabase `client_profiles` table (preferences merged in).
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

    // ── Size Preferences ──────────────────────
    let shoeSize: String?
    let ringSize: String?
    let braceletSize: String?
    let necklaceLength: String?
    let wristSize: String?
    let beltSize: String?

    // ── Category / Material Preferences ───────
    let favoriteCategories: [String]?
    let favoriteMetals: [String]?
    let favoriteGemstones: [String]?

    // ── Detailed Preferences ──────────────────
    let shoeFitPreference: String?
    let preferredMetal: String?
    let preferredGemstone: String?
    let watchCasePreference: String?
    let strapMaterialPreference: String?
    let preferredBagSize: String?
    let preferredBagStyle: String?
    let preferredMaterial: String?
    let bucklePreference: String?
    let fragranceFamily: String?
    let fragranceStrength: String?
    let scentPreference: String?
    let preferredBrands: String?
    let favoriteColors: String?
    let stylePreference: String?
    let giftingPreference: String?
    let shoppingPreference: String?

    enum CodingKeys: String, CodingKey {
        case id, email, phone, notes
        case fullName              = "full_name"
        case preferredStoreId      = "preferred_store_id"
        case vipTier               = "vip_tier"
        case privacyConsentGiven   = "privacy_consent_given"
        case consentDate           = "consent_date"
        case createdAt             = "created_at"
        case updatedAt             = "updated_at"

        // Sizes
        case shoeSize              = "shoe_size"
        case ringSize              = "ring_size"
        case braceletSize          = "bracelet_size"
        case necklaceLength        = "necklace_length"
        case wristSize             = "wrist_size"
        case beltSize              = "belt_size"

        // Arrays
        case favoriteCategories    = "favorite_categories"
        case favoriteMetals        = "favorite_metals"
        case favoriteGemstones     = "favorite_gemstones"

        // Detailed prefs
        case shoeFitPreference     = "shoe_fit_preference"
        case preferredMetal        = "preferred_metal"
        case preferredGemstone     = "preferred_gemstone"
        case watchCasePreference   = "watch_case_preference"
        case strapMaterialPreference = "strap_material_preference"
        case preferredBagSize      = "preferred_bag_size"
        case preferredBagStyle     = "preferred_bag_style"
        case preferredMaterial     = "preferred_material"
        case bucklePreference      = "buckle_preference"
        case fragranceFamily       = "fragrance_family"
        case fragranceStrength     = "fragrance_strength"
        case scentPreference       = "scent_preference"
        case preferredBrands       = "preferred_brands"
        case favoriteColors        = "favorite_colors"
        case stylePreference       = "style_preference"
        case giftingPreference     = "gifting_preference"
        case shoppingPreference    = "shopping_preference"
    }
}

enum VIPTier: String, Codable, CaseIterable {
    case standard = "standard"
    case silver   = "silver"
    case gold     = "gold"
    case platinum = "platinum"
    case prive    = "prive"
    case vip      = "vip"
}

// MARK: - Client Anniversary

/// Important dates for a client (birthday, wedding, etc.).
/// Maps to Supabase `client_anniversaries`.
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

/// A product on a client's wishlist.
/// Maps to Supabase `wishlist_items`.
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
        case clientId        = "client_id"
        case productId       = "product_id"
        case addedAt         = "added_at"
        case isAvailable     = "is_available"
        case notifyOnRestock = "notify_on_restock"
    }
}

// MARK: - Appointment

/// A scheduled client appointment (in-store, video, or phone).
/// Maps to Supabase `appointments`.
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
    
    // ── Reminders ──────────────────────────────
    let reminderTimingHours: Int
    let reminderChannel: String
    let reminderStatus: String
    let reminderError: String?

    enum CodingKeys: String, CodingKey {
        case id, type, status, notes
        case clientId            = "client_id"
        case associateId         = "associate_id"
        case storeId             = "store_id"
        case dateTime            = "date_time"
        case durationMinutes     = "duration_minutes"
        case reminderSentAt      = "reminder_sent_at"
        case videoLink           = "video_link"
        case createdAt           = "created_at"
    }

    enum ReminderKeys: String, CodingKey {
        case reminderTimingHours = "reminder_timing_hours"
        case reminderChannel     = "reminder_channel"
        case reminderStatus      = "reminder_status"
        case reminderError       = "reminder_error"
    }

    init(id: UUID, clientId: UUID, associateId: UUID, storeId: UUID, dateTime: Date, durationMinutes: Int, type: AppointmentType, status: AppointmentStatus, reminderSentAt: Date?, videoLink: String?, notes: String?, createdAt: Date, reminderTimingHours: Int = 24, reminderChannel: String = "Email", reminderStatus: String = "Pending", reminderError: String? = nil) {
        self.id = id
        self.clientId = clientId
        self.associateId = associateId
        self.storeId = storeId
        self.dateTime = dateTime
        self.durationMinutes = durationMinutes
        self.type = type
        self.status = status
        self.reminderSentAt = reminderSentAt
        self.videoLink = videoLink
        self.notes = notes
        self.createdAt = createdAt
        self.reminderTimingHours = reminderTimingHours
        self.reminderChannel = reminderChannel
        self.reminderStatus = reminderStatus
        self.reminderError = reminderError
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        clientId = try container.decode(UUID.self, forKey: .clientId)
        associateId = try container.decode(UUID.self, forKey: .associateId)
        storeId = try container.decode(UUID.self, forKey: .storeId)
        dateTime = try container.decode(Date.self, forKey: .dateTime)
        durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        type = try container.decode(AppointmentType.self, forKey: .type)
        status = try container.decode(AppointmentStatus.self, forKey: .status)
        reminderSentAt = try container.decodeIfPresent(Date.self, forKey: .reminderSentAt)
        videoLink = try container.decodeIfPresent(String.self, forKey: .videoLink)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)

        // Try to decode reminder keys, or fall back to default values if they don't exist in DB response yet
        let reminderContainer = try? decoder.container(keyedBy: ReminderKeys.self)
        reminderTimingHours = (try? reminderContainer?.decode(Int.self, forKey: .reminderTimingHours)) ?? 24
        reminderChannel = (try? reminderContainer?.decode(String.self, forKey: .reminderChannel)) ?? "Email"
        reminderStatus = (try? reminderContainer?.decode(String.self, forKey: .reminderStatus)) ?? "Pending"
        reminderError = try? reminderContainer?.decodeIfPresent(String.self, forKey: .reminderError)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(clientId, forKey: .clientId)
        try container.encode(associateId, forKey: .associateId)
        try container.encode(storeId, forKey: .storeId)
        try container.encode(dateTime, forKey: .dateTime)
        try container.encode(durationMinutes, forKey: .durationMinutes)
        try container.encode(type, forKey: .type)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(reminderSentAt, forKey: .reminderSentAt)
        try container.encodeIfPresent(videoLink, forKey: .videoLink)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(createdAt, forKey: .createdAt)
        
        // Exclude reminder fields during encoding so we don't cause 400 Bad Request / DB errors
        // against the live database instances that don't have these columns.
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

// MARK: - AI Recommendation

/// An AI-generated product recommendation for a client.
/// Maps to Supabase `ai_recommendations`.
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
/// Maps to Supabase `look_builder_outfits`.
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

// MARK: - FaceTime Configuration Support

/// Multi-field configuration for FaceTime consultations, serialized into the database videoLink property.
struct FaceTimeConfig: Codable, Hashable {
    var contact: String        // FaceTime email or phone number
    var meetingLink: String?   // FaceTime meeting link (optional)
    var notes: String?         // FaceTime specific notes / instructions (optional)
}

extension Appointment {
    /// Decodes the JSON FaceTime configuration stored in `videoLink`, or falls back to treating it as a raw string if legacy.
    var decodedFaceTimeConfig: FaceTimeConfig? {
        guard let videoLink = videoLink, !videoLink.isEmpty else { return nil }
        if let data = videoLink.data(using: .utf8),
           let config = try? JSONDecoder().decode(FaceTimeConfig.self, from: data) {
            return config
        }
        // Graceful fallback for legacy raw URLs
        return FaceTimeConfig(contact: videoLink, meetingLink: videoLink, notes: nil)
    }
}

