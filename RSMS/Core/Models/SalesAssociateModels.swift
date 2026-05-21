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
