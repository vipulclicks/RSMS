//
//  OrderModels.swift
//  RSMS
//

import Foundation

struct Order: Codable, Identifiable, Hashable {
    let id: UUID
    let clientId: UUID
    let transactionId: UUID
    let cartId: UUID
    let status: OrderStatus
    let totalAmount: Double
    let discountAmount: Double
    let finalAmount: Double
    let createdAt: Date
    
    // BOPIS Extensions
    let fulfillmentMethod: String?
    let pickupStoreId: UUID?
    let shippingAddress: String?
    let checkoutSessionId: UUID?

    init(
        id: UUID,
        clientId: UUID,
        transactionId: UUID,
        cartId: UUID,
        status: OrderStatus,
        totalAmount: Double,
        discountAmount: Double,
        finalAmount: Double,
        createdAt: Date,
        fulfillmentMethod: String? = nil,
        pickupStoreId: UUID? = nil,
        shippingAddress: String? = nil,
        checkoutSessionId: UUID? = nil
    ) {
        self.id = id
        self.clientId = clientId
        self.transactionId = transactionId
        self.cartId = cartId
        self.status = status
        self.totalAmount = totalAmount
        self.discountAmount = discountAmount
        self.finalAmount = finalAmount
        self.createdAt = createdAt
        self.fulfillmentMethod = fulfillmentMethod
        self.pickupStoreId = pickupStoreId
        self.shippingAddress = shippingAddress
        self.checkoutSessionId = checkoutSessionId
    }

    enum CodingKeys: String, CodingKey {
        case id, status
        case clientId       = "client_id"
        case transactionId  = "transaction_id"
        case cartId         = "cart_id"
        case totalAmount    = "total_amount"
        case discountAmount = "discount_amount"
        case finalAmount    = "final_amount"
        case createdAt      = "created_at"
        case fulfillmentMethod = "fulfillment_method"
        case pickupStoreId  = "pickup_store_id"
        case shippingAddress = "shipping_address"
        case checkoutSessionId = "checkout_session_id"
    }
}

enum OrderStatus: String, Codable, CaseIterable {
    case confirmed = "confirmed"
    case processing = "processing"
    case shipped = "shipped"
    case delivered = "delivered"
    case cancelled = "cancelled"
}
