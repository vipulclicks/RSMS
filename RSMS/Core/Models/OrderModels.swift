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

    enum CodingKeys: String, CodingKey {
        case id, status
        case clientId       = "client_id"
        case transactionId  = "transaction_id"
        case cartId         = "cart_id"
        case totalAmount    = "total_amount"
        case discountAmount = "discount_amount"
        case finalAmount    = "final_amount"
        case createdAt      = "created_at"
    }
}

enum OrderStatus: String, Codable, CaseIterable {
    case confirmed = "confirmed"
    case processing = "processing"
    case shipped = "shipped"
    case delivered = "delivered"
    case cancelled = "cancelled"
}
