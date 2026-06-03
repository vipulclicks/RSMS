//
//  BOPISModels.swift
//  RSMS
//

import Foundation

// MARK: - Enums

enum CheckoutStatus: String, Codable, CaseIterable, Identifiable {
    case draft = "draft"
    case linkGenerated = "linkGenerated"
    case viewed = "viewed"
    case pendingPayment = "pendingPayment"
    case pendingStorePayment = "pendingStorePayment"
    case paid = "paid"
    case readyForPickup = "readyForPickup"
    case readyForShipping = "readyForShipping"
    case completed = "completed"
    case expired = "expired"
    case cancelled = "cancelled"
    
    var id: String { rawValue }
}

enum FulfillmentMethod: String, Codable, CaseIterable {
    case pickup = "pickup"
    case shipping = "shipping"
}

enum CheckoutPaymentMethod: String, Codable, CaseIterable {
    case online = "online"
    case instore = "instore"
}

// MARK: - Models

struct CheckoutSession: Codable, Identifiable, Hashable {
    let id: UUID
    let cartId: UUID
    let token: String
    let clientId: UUID
    let associateId: UUID
    let status: CheckoutStatus
    let fulfillmentMethod: FulfillmentMethod?
    let paymentMethod: CheckoutPaymentMethod?
    let expiresAt: Date
    let createdAt: Date
    let updatedAt: Date
    var scheduledPickupAt: Date?   // Set by associate after payment to schedule pickup slot
    var pickupCode: String?        // 6-digit code for verifying pickup

    enum CodingKeys: String, CodingKey {
        case id, token, status
        case cartId = "cart_id"
        case clientId = "client_id"
        case associateId = "associate_id"
        case fulfillmentMethod = "fulfillment_method"
        case paymentMethod = "payment_method"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case scheduledPickupAt = "scheduled_pickup_at"
        case pickupCode = "pickup_code"
    }
}

struct CheckoutShippingAddress: Codable, Identifiable, Hashable {
    let id: UUID
    let checkoutSessionId: UUID
    let name: String
    let phone: String
    let address: String
    let city: String
    let state: String
    let pincode: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, phone, address, city, state, pincode
        case checkoutSessionId = "checkout_session_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct InventoryReservation: Codable, Identifiable, Hashable {
    let id: UUID
    let checkoutSessionId: UUID
    let productId: UUID
    let quantity: Int
    let storeId: UUID
    let status: ReservationStatus
    let createdAt: Date
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case id, quantity, status
        case checkoutSessionId = "checkout_session_id"
        case productId = "product_id"
        case storeId = "store_id"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
}

enum ReservationStatus: String, Codable, CaseIterable {
    case reserved = "reserved"
    case released = "released"
    case fulfilled = "fulfilled"
}
