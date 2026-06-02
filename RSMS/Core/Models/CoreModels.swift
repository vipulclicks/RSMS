//
//  CoreModels.swift
//  RSMS
//
//  RSMS_Mock_Data
//

import Foundation

// MARK: - User Role

/// Role-based access control enum matching Supabase `user_role` CHECK constraint.
enum UserRole: String, Codable, CaseIterable, Identifiable {
    case boutiqueManager     = "boutique_manager"
    case salesAssociate      = "sales_associate"
    case inventoryController = "inventory_controller"
    case client              = "client"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .boutiqueManager:      return "Boutique Manager"
        case .salesAssociate:       return "Sales Associate"
        case .inventoryController:  return "Inventory Controller"
        case .client:               return "Client Profile"
        }
    }
}

// MARK: - Store

/// Represents a physical boutique / retail store.
struct Store: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let code: String
    let country: String
    let city: String
    let address: String
    let timezone: String
    let phone: String?
    let email: String?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, code, country, city, address, timezone, phone, email
        case isActive    = "is_active"
        case createdAt   = "created_at"
        case updatedAt   = "updated_at"
    }
}

// MARK: - User Profile

/// Application user linked to Supabase Auth. Contains role and store assignment.
struct UserProfile: Codable, Identifiable, Hashable {
    let id: UUID
    let email: String
    let fullName: String
    let role: UserRole
    let storeId: UUID?
    let avatarURL: String?
    let phone: String?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, email, role, phone
        case fullName   = "full_name"
        case storeId    = "store_id"
        case avatarURL  = "avatar_url"
        case isActive   = "is_active"
        case createdAt  = "created_at"
        case updatedAt  = "updated_at"
    }
}

/// Payload sent to Supabase to update only the allowed (editable) fields of a UserProfile.
struct UserProfileUpdatePayload: Codable {
    let phone: String?
    let avatarURL: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case phone
        case avatarURL = "avatar_url"
        case updatedAt = "updated_at"
    }
}



